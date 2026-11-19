import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

declare const Deno: {
  env: { get(key: string): string | undefined }
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
}

const requiredEnv = [
  "SUPABASE_URL",
  "SUPABASE_SERVICE_ROLE_KEY",
  "UCALLER_KEY",
  "UCALLER_SERVICE_ID",
] as const

const env = requiredEnv.reduce<Record<string, string>>((acc, key) => {
  const value = Deno.env.get(key)
  if (!value) throw new Error(`Missing env ${key}`)
  acc[key] = value
  return acc
}, {})

const supabase = createClient(env["SUPABASE_URL"], env["SUPABASE_SERVICE_ROLE_KEY"], {
  auth: { autoRefreshToken: false, persistSession: false },
  global: { headers: { "x-application-name": "sms-auth" } },
})

const OTP_LENGTH = 4
const OTP_TTL_SECONDS = 300
const RATE_LIMIT_SECONDS = 20
const MAX_VERIFY_ATTEMPTS = 5
const MAX_CALLS_PER_MINUTE = 4
const MAX_CALLS_PER_DAY = 30

function generateOtp(): string {
  const min = Math.pow(10, OTP_LENGTH - 1)
  const max = Math.pow(10, OTP_LENGTH) - 1
  return String(Math.floor(Math.random() * (max - min + 1)) + min)
}

function generateUUID(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === "x" ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

function normalizePhone(raw: string): string | null {
  const digits = raw.replace(/\D/g, "")
  if (digits.length === 11 && (digits.startsWith("7") || digits.startsWith("8"))) {
    return "7" + digits.slice(1)
  }
  if (digits.length === 10) {
    return "7" + digits
  }
  return null
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

async function findUserByPhone(normalized: string) {
  const phoneWithPlus = `+${normalized}`
  let page = 1
  const perPage = 1000
  while (true) {
    const { data: pageData, error: pageError } = await supabase.auth.admin.listUsers({
      page,
      perPage,
    })
    if (pageError || !pageData?.users || pageData.users.length === 0) return null
    const existingUser = pageData.users.find(
      (u) => u.phone === phoneWithPlus || u.phone === normalized,
    )
    if (existingUser) return existingUser
    if (pageData.users.length < perPage) return null
    page++
  }
}

// ──────────────────────────────────────────────
// send_otp: generate fresh code, initiate uCaller flash call
// ──────────────────────────────────────────────
async function handleSendOtp(phone: string, mode?: string): Promise<Response> {
  const normalized = normalizePhone(phone)
  if (!normalized) {
    return json({ error: "Неверный формат телефона. Используйте +7XXXXXXXXXX." }, 400)
  }

  if (mode === "register" || mode === "reset") {
    const existingUser = await findUserByPhone(normalized)
    if (mode === "register" && existingUser) {
      return json({ error: "Этот номер уже используется. Войдите в аккаунт." }, 409)
    }
    if (mode === "reset" && !existingUser) {
      return json({ error: "Аккаунт с таким номером не найден." }, 404)
    }
  }

  // --- Rate limit: 15 sec between calls to same number ---
  const { data: recentCalls } = await supabase
    .from("phone_otps")
    .select("created_at, last_call_at")
    .eq("phone", normalized)
    .eq("verified", false)
    .gte("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(1)

  if (recentCalls && recentCalls.length > 0) {
    const lastCall = recentCalls[0].last_call_at || recentCalls[0].created_at
    const elapsed = Date.now() - new Date(lastCall).getTime()
    if (elapsed < RATE_LIMIT_SECONDS * 1000) {
      const waitSec = Math.ceil((RATE_LIMIT_SECONDS * 1000 - elapsed) / 1000)
      return json({ error: `Подождите ${waitSec} сек. перед повторной отправкой.` }, 429)
    }
  }

  // --- Daily limit: 30 calls per number per day ---
  const dayStart = new Date()
  dayStart.setUTCHours(0, 0, 0, 0)
  const { data: dailyCalls } = await supabase
    .from("phone_otps")
    .select("call_count")
    .eq("phone", normalized)
    .gte("created_at", dayStart.toISOString())

  const totalCallsToday = (dailyCalls || []).reduce(
    (sum, row) => sum + (row.call_count || 1), 0,
  )
  if (totalCallsToday >= MAX_CALLS_PER_DAY) {
    return json({ error: "Превышен дневной лимит звонков. Попробуйте завтра." }, 429)
  }

  const code = generateOtp()
  const expiresAt = new Date(Date.now() + OTP_TTL_SECONDS * 1000).toISOString()
  const now = new Date().toISOString()

  const { data: inserted, error: insertError } = await supabase
    .from("phone_otps")
    .insert({
      phone: normalized,
      code,
      expires_at: expiresAt,
      call_count: 1,
      last_call_at: now,
    })
    .select("id")
    .single()

  if (insertError || !inserted) {
    console.error("OTP insert error:", insertError)
    return json({ error: "Внутренняя ошибка. Попробуйте позже." }, 500)
  }
  const otpId = inserted.id

  const ucallerUrl = "https://api.ucaller.ru/v1.0/initCall"
  const uniqueId = generateUUID()

  try {
    const ucallerRes = await fetch(ucallerUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${env["UCALLER_KEY"]}.${env["UCALLER_SERVICE_ID"]}`,
      },
      body: JSON.stringify({
        phone: Number(normalized),
        code: Number(code),
        unique: uniqueId,
      }),
    })

    const ucallerBody = await ucallerRes.text()
    let ucallerJson: Record<string, unknown> = {}
    try {
      ucallerJson = JSON.parse(ucallerBody)
    } catch {
      // Non-JSON response
    }

    if (ucallerJson["status"] !== true) {
      const errorCode = ucallerJson["code"] ?? "unknown"
      console.error("uCaller error:", ucallerBody)
      await supabase.from("phone_otps").delete().eq("id", otpId)

      if (errorCode === 18 || errorCode === 19) {
        return json({ error: "Слишком частые запросы. Подождите 20 секунд." }, 429)
      }
      if (errorCode === 3) {
        return json({ error: "Неверный номер телефона." }, 400)
      }
      return json({ error: "Не удалось совершить звонок. Попробуйте позже." }, 502)
    }

    // Store ucaller_id for tracking.
    await supabase
      .from("phone_otps")
      .update({
        ucaller_id: String(ucallerJson["ucaller_id"]),
      })
      .eq("id", otpId)

    return json({
      success: true,
      phone: normalized,
      ucaller_id: ucallerJson["ucaller_id"],
    })
  } catch (err) {
    console.error("uCaller fetch error:", err)
    return json({ error: "Ошибка связи с сервисом звонков." }, 502)
  }
}

// ──────────────────────────────────────────────
// verify_otp: check code, create/find user, return session
// ──────────────────────────────────────────────
async function handleVerifyOtp(phone: string, code: string, mode?: string): Promise<Response> {
  const normalized = normalizePhone(phone)
  if (!normalized) {
    return json({ error: "Неверный формат телефона." }, 400)
  }
  if (!code || code.length !== OTP_LENGTH) {
    return json({ error: `Код должен содержать ${OTP_LENGTH} цифры.` }, 400)
  }

  const { data: otpRows, error: fetchError } = await supabase
    .from("phone_otps")
    .select("*")
    .eq("phone", normalized)
    .eq("verified", false)
    .gte("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(1)

  if (fetchError || !otpRows || otpRows.length === 0) {
    return json({ error: "Код не найден или истёк. Запросите новый." }, 400)
  }

  const otpRecord = otpRows[0]

  if (otpRecord.attempts >= MAX_VERIFY_ATTEMPTS) {
    await supabase
      .from("phone_otps")
      .update({ verified: true })
      .eq("id", otpRecord.id)
    return json({ error: "Превышено количество попыток. Запросите новый код." }, 429)
  }

  await supabase
    .from("phone_otps")
    .update({ attempts: otpRecord.attempts + 1 })
    .eq("id", otpRecord.id)

  if (otpRecord.code !== code) {
    const remaining = MAX_VERIFY_ATTEMPTS - otpRecord.attempts - 1
    return json({
      error: `Неверный код. Осталось попыток: ${remaining}.`,
    }, 400)
  }

  await supabase
    .from("phone_otps")
    .update({ verified: true })
    .eq("id", otpRecord.id)

  const phoneWithPlus = `+${normalized}`
  let userId: string
  let existingUser: { id: string; user_metadata?: Record<string, unknown> } | null =
    await findUserByPhone(normalized) as { id: string; user_metadata?: Record<string, unknown> } | null

  let isNewUser = false

  if (existingUser) {
    if (mode === "register") {
      return json({ error: "Этот номер уже используется. Войдите в аккаунт." }, 409)
    }
    userId = existingUser.id
    const metadata = existingUser.user_metadata
    const passwordReady = metadata?.["phone_password_set"] === true
    // Existing user without configured password should still see password setup screen.
    isNewUser = !passwordReady
  } else {
    if (mode === "reset") {
      return json({ error: "Аккаунт с таким номером не найден." }, 404)
    }
    isNewUser = true
    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      phone: phoneWithPlus,
      phone_confirm: true,
      user_metadata: {
        phone_password_set: false,
      },
    })

    if (createError || !newUser?.user) {
      console.error("Create user error:", createError)
      return json({ error: "Не удалось создать аккаунт. Попробуйте позже." }, 500)
    }
    userId = newUser.user.id

    // Auto-create profile so home page works immediately
    const { error: profileError } = await supabase.from("profiles").insert({
      user_id: userId,
      phone: phoneWithPlus,
      balance: 0,
    })
    if (profileError) {
      console.error("Profile insert error (non-fatal):", profileError)
    }
  }

  const placeholderEmail = `phone_${normalized}@ingooz.local`

  await supabase.auth.admin.updateUserById(userId, {
    phone: phoneWithPlus,
    phone_confirm: true,
    email: placeholderEmail,
    email_confirm: true,
  })

  const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
    type: "magiclink",
    email: placeholderEmail,
  })

  if (linkError) {
    console.error("generateLink error:", linkError)
    return json({ error: "Не удалось авторизовать. Попробуйте позже." }, 500)
  }

  if (linkData?.properties?.access_token && linkData?.properties?.refresh_token) {
    return json({
      access_token: linkData.properties.access_token,
      refresh_token: linkData.properties.refresh_token,
      user: { id: userId, phone: phoneWithPlus },
      is_new: isNewUser,
    })
  }

  if (linkData?.properties?.action_link) {
    const actionUrl = new URL(linkData.properties.action_link)
    const token = actionUrl.searchParams.get("token") || ""
    const type = actionUrl.searchParams.get("type") || "magiclink"

    const { data: verifyData, error: verifyError } = await supabase.auth.verifyOtp({
      token_hash: token,
      type: type as "magiclink",
    })

    if (verifyError) {
      console.error("verifyOtp error:", verifyError)
      return json({ error: "Не удалось авторизовать. Попробуйте позже." }, 500)
    }

    if (verifyData?.session) {
      return json({
        access_token: verifyData.session.access_token,
        refresh_token: verifyData.session.refresh_token,
        user: { id: userId, phone: phoneWithPlus },
        is_new: isNewUser,
      })
    }
  }

  return json({ error: "Не удалось получить сессию. Попробуйте позже." }, 500)
}

// ──────────────────────────────────────────────
// Main handler
// ──────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 })
  }

  try {
    const body = await req.json()
    const { action, phone, code, mode } = body as {
      action?: string
      phone?: string
      code?: string
      mode?: string
    }

    if (!action || !phone) {
      return json({ error: "Требуются поля action и phone." }, 400)
    }

    switch (action) {
      case "send_otp":
        return await handleSendOtp(phone, mode)
      case "verify_otp":
        if (!code) {
          return json({ error: "Требуется поле code." }, 400)
        }
        return await handleVerifyOtp(phone, code, mode)
      default:
        return json({ error: `Неизвестное действие: ${action}` }, 400)
    }
  } catch (err) {
    console.error("Unhandled error:", err)
    const message = err instanceof Error ? err.message : "Unexpected error"
    return json({ error: message }, 500)
  }
})
