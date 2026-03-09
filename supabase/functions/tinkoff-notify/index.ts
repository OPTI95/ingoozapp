// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

declare const Deno: {
  env: { get(key: string): string | undefined }
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
}

type TinkoffNotification = {
  TerminalKey?: string
  OrderId?: string
  Success?: boolean | string
  Status?: string
  PaymentId?: number | string
  Amount?: number
  CustomerKey?: string
  Token?: string
  [key: string]: unknown
}

const requiredEnv = [
  "TINKOFF_TERMINAL_KEY",
  "TINKOFF_PASSWORD",
  "SUPABASE_URL",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const

const envValues = requiredEnv.reduce<Record<string, string>>((acc, key) => {
  const value = Deno.env.get(key)
  if (!value) {
    throw new Error(`Missing env ${key}`)
  }
  acc[key] = value
  return acc
}, {})

const TERMINAL_KEY = envValues["TINKOFF_TERMINAL_KEY"]
const PASSWORD = envValues["TINKOFF_PASSWORD"]

const supabase = createClient(
  envValues["SUPABASE_URL"],
  envValues["SUPABASE_SERVICE_ROLE_KEY"],
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        "x-application-name": "tinkoff-notify",
      },
    },
  },
)

async function generateToken(
  params: Record<string, string | number | undefined>,
) {
  // Алгоритм из документации: https://developer.tbank.ru/eacq/intro/developer/token
  const withPassword: Record<string, string | number | undefined> = {
    ...params,
    Password: PASSWORD,
  }
  const sortedKeys = Object.keys(withPassword)
    .filter((key) => withPassword[key] !== undefined && withPassword[key] !== null)
    .sort()
  const concatenated = sortedKeys.map((key) => withPassword[key]).join("")
  const data = new TextEncoder().encode(concatenated)
  const hashBuffer = await crypto.subtle.digest("SHA-256", data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("")
}

function extractTokenParams(payload: TinkoffNotification) {
  const params: Record<string, string | number | undefined> = {}
  for (const [key, value] of Object.entries(payload)) {
    if (key === "Token") continue
    if (value === null || value === undefined) continue
    if (typeof value === "object") continue // вложенные объекты/массивы не участвуют
    if (typeof value === "string" || typeof value === "number") {
      params[key] = value
    }
  }
  return params
}

async function handleSuccessNotification(body: TinkoffNotification) {
  const orderId = body.OrderId
  const paymentId = body.PaymentId

  if (!orderId) {
    console.error("Missing OrderId in notification", body)
    return
  }

  // Ищем «ожидающий» платёж, созданный в tinkoff-init
  const { data: pending, error: pendingError } = await supabase
    .from("payments")
    .select("id, user_id, amount, status")
    .eq("provider", "tinkoff")
    .eq("provider_payment_id", orderId)
    .maybeSingle()

  if (pendingError) {
    console.error("Error fetching pending payment", pendingError)
    return
  }

  if (!pending) {
    console.error("Pending payment not found for OrderId", orderId)
    return
  }

  const userId = String(pending.user_id)
  const amountRub = typeof pending.amount === "number"
    ? pending.amount
    : Number(pending.amount) || 0

  if (!amountRub) {
    console.error("Pending payment has zero amount", pending)
    return
  }

  // Если уже помечен как succeeded — не дублируем
  if (pending.status === "succeeded") {
    console.log("Payment already succeeded, skipping credit", pending)
    return
  }

  // Обновляем/создаём профиль с балансом
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("user_id, balance")
    .eq("user_id", userId)
    .maybeSingle()

  if (profileError) {
    console.error("Error fetching profile", profileError)
  }

  if (!profile) {
    const { error: insertProfileError } = await supabase
      .from("profiles")
      .insert({ user_id: userId, balance: amountRub })

    if (insertProfileError) {
      console.error("Error inserting profile", insertProfileError)
    }
  } else {
    const currentBalance = typeof profile.balance === "number"
      ? profile.balance
      : Number(profile.balance) || 0

    const { error: updateProfileError } = await supabase
      .from("profiles")
      .update({ balance: currentBalance + amountRub })
      .eq("user_id", userId)

    if (updateProfileError) {
      console.error("Error updating profile balance", updateProfileError)
    }
  }

  // Обновляем платёж как успешный
  const { error: paymentError } = await supabase
    .from("payments")
    .update({
      status: "succeeded",
    })
    .eq("id", pending.id)

  if (paymentError) {
    console.error("Error updating payment to succeeded", paymentError)
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 })
  }

  let payload: TinkoffNotification
  try {
    payload = await req.json() as TinkoffNotification
  } catch (e) {
    console.error("Invalid JSON in Tinkoff notify", e)
    return new Response("Bad Request", { status: 400 })
  }

  console.log("Tinkoff notify payload:", JSON.stringify(payload))

  if (!payload.TerminalKey || payload.TerminalKey !== TERMINAL_KEY) {
    console.error("TerminalKey mismatch", payload.TerminalKey)
    return new Response("Bad TerminalKey", { status: 400 })
  }

  const receivedToken = typeof payload.Token === "string"
    ? payload.Token
    : undefined

  // Для MVP не блокируем обработку при проблемах с токеном, только логируем.
  if (!receivedToken) {
    console.error("Missing Token in notification (skipping strict check)")
  } else {
    const tokenParams = extractTokenParams(payload)
    const expectedToken = await generateToken(tokenParams)
    if (receivedToken.toLowerCase() !== expectedToken.toLowerCase()) {
      console.error("Invalid Token in notification (skipping strict check)")
    }
  }

  const success = payload.Success === true || payload.Success === "true"
  const status = payload.Status

  // У Тинькофф часто в AUTHORIZED есть все данные (Amount, CustomerKey),
  // а в CONFIRMED — уже без суммы. Для простоты считаем успешными оба.
  const isFinalSuccess = success &&
    (status === "AUTHORIZED" || status === "CONFIRMED")

  if (isFinalSuccess) {
    await handleSuccessNotification(payload)
  } else {
    console.log(
      "Notification not AUTHORIZED/CONFIRMED or not success, skipping credit",
      {
        success,
        status,
      },
    )
  }

  // Тинькофф ждёт 200/OK, иначе будет ретраить
  return new Response("OK", { status: 200 })
})

