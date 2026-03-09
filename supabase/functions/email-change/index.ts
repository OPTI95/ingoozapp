import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

declare const Deno: {
  env: { get(key: string): string | undefined }
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
}

type EmailChangeRequestRow = {
  id: string
  user_id: string
  new_email: string
  confirm_token: string
  expires_at: string
  used_at: string | null
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

if (!SUPABASE_URL || !SERVICE_ROLE) {
  throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { autoRefreshToken: false, persistSession: false },
})

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

function bearerToken(req: Request): string | null {
  const header = req.headers.get("Authorization") ?? ""
  const m = header.match(/^Bearer\s+(.+)$/i)
  return m?.[1] ?? null
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

async function requireUser(req: Request) {
  const token = bearerToken(req)
  if (!token) return { error: "Missing auth token" as const }
  const {
    data: { user },
    error: userError,
  } = await admin.auth.getUser(token)
  if (userError || !user) return { error: "Unauthorized" as const }
  return { user }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "Method Not Allowed" })

  let payload: { action?: string; new_email?: string; request_id?: string; confirm_token?: string } = {}
  try {
    payload = await req.json()
  } catch {
    return json(400, { error: "Invalid JSON body" })
  }

  const action = payload.action
  if (action == "request") {
    const auth = await requireUser(req)
    if ("error" in auth) return json(401, { error: auth.error })
    const user = auth.user

    const newEmail = (payload.new_email ?? "").trim().toLowerCase()
    if (!isValidEmail(newEmail)) return json(400, { error: "Invalid email" })
    if ((user.email ?? "").toLowerCase() == newEmail) {
      return json(400, { error: "Новый email совпадает с текущим" })
    }

    const { data: emailStatus, error: emailStatusError } = await admin.rpc(
      "check_email_status",
      { user_email: newEmail },
    )
    if (emailStatusError) return json(500, { error: emailStatusError.message })
    const exists =
      Array.isArray(emailStatus) &&
      emailStatus.length > 0 &&
      emailStatus[0]?.email_exists === true
    if (exists) return json(409, { error: "Этот email уже используется" })

    await admin
      .from("email_change_requests")
      .delete()
      .eq("user_id", user.id)
      .is("used_at", null)

    const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString()
    const confirmToken = crypto.randomUUID().replaceAll("-", "") + crypto.randomUUID().replaceAll("-", "")
    const { data: inserted, error: insertError } = await admin
      .from("email_change_requests")
      .insert({
        user_id: user.id,
        new_email: newEmail,
        confirm_token: confirmToken,
        expires_at: expiresAt,
      })
      .select("id, confirm_token")
      .single()

    if (insertError || !inserted) {
      return json(500, { error: insertError?.message ?? "Insert failed" })
    }
    return json(200, {
      request_id: inserted.id,
      confirm_token: inserted.confirm_token,
      expires_at: expiresAt,
    })
  }

  if (action == "confirm_latest") {
    const auth = await requireUser(req)
    if ("error" in auth) return json(401, { error: auth.error })
    const user = auth.user

    const { data: row, error: rowError } = await admin
      .from("email_change_requests")
      .select("id, user_id, new_email, confirm_token, expires_at, used_at")
      .eq("user_id", user.id)
      .is("used_at", null)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle<EmailChangeRequestRow>()

    if (rowError) return json(500, { error: rowError.message })
    if (!row) return json(404, { error: "Нет активного запроса смены email" })
    if (new Date(row.expires_at).getTime() < Date.now()) {
      return json(410, { error: "Ссылка устарела" })
    }

    const { data: emailStatus, error: emailStatusError } = await admin.rpc(
      "check_email_status",
      { user_email: row.new_email },
    )
    if (emailStatusError) return json(500, { error: emailStatusError.message })
    const exists =
      Array.isArray(emailStatus) &&
      emailStatus.length > 0 &&
      emailStatus[0]?.email_exists === true
    if (exists) return json(409, { error: "Этот email уже используется" })

    const { error: updateError } = await admin.auth.admin.updateUserById(
      user.id,
      {
        email: row.new_email,
        email_confirm: true,
      },
    )
    if (updateError) return json(500, { error: updateError.message })

    const { error: markError } = await admin
      .from("email_change_requests")
      .update({ used_at: new Date().toISOString() })
      .eq("id", row.id)
    if (markError) return json(500, { error: markError.message })

    return json(200, { success: true, new_email: row.new_email })
  }

  if (action == "confirm") {
    const requestId = (payload.request_id ?? "").trim()
    const confirmToken = (payload.confirm_token ?? "").trim()
    if (requestId.length === 0) {
      return json(400, { error: "request_id is required" })
    }
    if (confirmToken.length === 0) {
      return json(400, { error: "confirm_token is required" })
    }

    const { data: row, error: rowError } = await admin
      .from("email_change_requests")
      .select("id, user_id, new_email, confirm_token, expires_at, used_at")
      .eq("id", requestId)
      .single<EmailChangeRequestRow>()

    if (rowError || !row) return json(404, { error: "Запрос не найден" })
    if (row.confirm_token != confirmToken) return json(403, { error: "Некорректный токен подтверждения" })
    if (row.used_at != null) return json(409, { error: "Ссылка уже использована" })
    if (new Date(row.expires_at).getTime() < Date.now()) {
      return json(410, { error: "Ссылка устарела" })
    }

    const { data: emailStatus, error: emailStatusError } = await admin.rpc(
      "check_email_status",
      { user_email: row.new_email },
    )
    if (emailStatusError) return json(500, { error: emailStatusError.message })
    const exists =
      Array.isArray(emailStatus) &&
      emailStatus.length > 0 &&
      emailStatus[0]?.email_exists === true
    if (exists) return json(409, { error: "Этот email уже используется" })

    const { error: updateError } = await admin.auth.admin.updateUserById(
      row.user_id,
      {
        email: row.new_email,
        email_confirm: true,
      },
    )
    if (updateError) return json(500, { error: updateError.message })

    const { error: markError } = await admin
      .from("email_change_requests")
      .update({ used_at: new Date().toISOString() })
      .eq("id", row.id)
    if (markError) return json(500, { error: markError.message })

    return json(200, { success: true, new_email: row.new_email })
  }

  return json(400, { error: "Unknown action" })
})
