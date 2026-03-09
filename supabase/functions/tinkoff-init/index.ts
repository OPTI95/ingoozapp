    import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

declare const Deno: {
  env: { get(key: string): string | undefined }
  serve: (handler: (req: Request) => Response | Promise<Response>) => void
}

type InitResponse = {
  Success: boolean
  ErrorCode?: string
  Message?: string
  PaymentURL?: string
  OrderId?: string
  PaymentId?: number | string
}

const requiredEnv = [
  "TINKOFF_TERMINAL_KEY",
  "TINKOFF_PASSWORD",
  "TINKOFF_API_BASE",
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

const API_BASE = envValues["TINKOFF_API_BASE"].replace(/\/$/, "")
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
      headers: { "x-application-name": "tinkoff-init" },
    },
  },
)

// Optional: URL of a proxy with static IP (see supabase/functions/README.md).
// If set, Init request is sent via proxy to avoid Tinkoff 403 (IP whitelist).
const PROXY_URL = Deno.env.get("TINKOFF_PROXY_URL")

const TINKOFF_USER_AGENT = "IngoozApp-Tinkoff-Client/1.0"

async function generateToken(
  params: Record<string, string | number | undefined>,
) {
  // Документация: https://developer.tbank.ru/eacq/intro/developer/token
  // 1. Добавить Password в массив параметров
  // 2. Отсортировать по ключу
  // 3. Конкатенировать только значения
  // 4. SHA-256
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

async function callTinkoffInit(url: string, body: Record<string, unknown>) {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "User-Agent": TINKOFF_USER_AGENT,
  }
  const res = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  })
  const text = await res.text()
  if (!res.ok) {
    // 403 often = IP not whitelisted; return body for debugging
    const detail = text ? ` body=${text}` : ""
    throw new Error(`Tinkoff Init failed: ${res.status}${detail}`)
  }
  return JSON.parse(text || "{}") as InitResponse
}

async function callInit(
  amountRub: number,
  userId: string,
  returnUrl?: string,
): Promise<InitResponse> {
  // Тинькофф принимает Amount в копейках. Минимум 1 руб = 100 коп (для СБП — 10 руб).
  const amountKopecks = Math.round(amountRub * 100)
  if (amountKopecks < 100) {
    throw new Error("Минимальная сумма оплаты — 1 ₽ (100 копеек)")
  }

  const successUrl = returnUrl ?? Deno.env.get("TINKOFF_SUCCESS_URL")
  const failUrl = Deno.env.get("TINKOFF_FAIL_URL")
  const notificationUrl = Deno.env.get("TINKOFF_NOTIFY_URL")
  const orderId = crypto.randomUUID()
  // Тинькофф: CustomerKey и OrderId — макс. 36 символов (документация developer.tbank.ru/eacq/api/init).
  const customerKey = String(userId).slice(0, 36) || "guest"
  const isUrl = (s: string) => /^https?:\/\//.test(s.trim())
  const params: Record<string, string | number> = {
    TerminalKey: TERMINAL_KEY,
    Amount: amountKopecks,
    OrderId: orderId,
    Description: "Ingooz waybill top-up",
    CustomerKey: customerKey,
    Language: "ru",
    PayType: "O",
  }
  if (successUrl && isUrl(successUrl)) {
    params["SuccessURL"] = successUrl.trim()
  }
  if (failUrl && isUrl(failUrl)) {
    params["FailURL"] = failUrl.trim()
  }
  if (notificationUrl && isUrl(notificationUrl)) {
    params["NotificationURL"] = notificationUrl.trim()
  }

  const token = await generateToken(params)
  const body = { ...params, Token: token }
  // Документация: https://developer.tbank.ru/eacq/api/init
  // Тест: https://rest-api-test.tinkoff.ru/v2/Init
  // Боевая: https://securepay.tinkoff.ru/v2/Init (403 = запрос ушёл в тест, для реальных платежей — боевая среда)
  const initUrl = `${API_BASE}/v2/Init`

  if (PROXY_URL) {
    // Forward via proxy (static IP) to avoid Tinkoff 403
    const proxySecret = Deno.env.get("TINKOFF_PROXY_SECRET")
    const res = await fetch(PROXY_URL.replace(/\/$/, ""), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(proxySecret ? { "X-Proxy-Secret": proxySecret } : {}),
      },
      body: JSON.stringify({ url: initUrl, body }),
    })
    const raw = await res.text()
    if (!res.ok) {
      throw new Error(`Proxy failed: ${res.status} ${raw}`)
    }
    return JSON.parse(raw || "{}") as InitResponse
  }

  return callTinkoffInit(initUrl, body)
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 })
  }

  try {
    let body: { amount?: number; returnUrl?: string } = {}
    if (req.headers.get("content-length")) {
      body = await req.json()
    }
    const { amount = 100, returnUrl } = body

    const supabaseHeader = req.headers.get("x-supabase-user-id")
    const userId = supabaseHeader ?? crypto.randomUUID()

    const response = await callInit(amount, userId, returnUrl)
    if (!response.Success || !response.PaymentURL) {
      // Логируем полный ответ Тинькофф для отладки (Supabase → Edge Functions → Logs)
      console.error("Tinkoff Init rejected:", JSON.stringify(response))
      const msg = response.Message ?? "Init failed"
      const detail =
        response.ErrorCode != null
          ? { error: msg, errorCode: response.ErrorCode }
          : { error: msg }
      return new Response(JSON.stringify(detail), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    return new Response(
      JSON.stringify({
        paymentUrl: response.PaymentURL,
        orderId: response.OrderId,
      }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (error) {
    console.error(error)
    const message = error instanceof Error ? error.message : "Unexpected error"
    const isValidation = message.includes("Минимальная сумма")
    return new Response(
      JSON.stringify({ error: message }),
      {
        status: isValidation ? 400 : 500,
        headers: { "Content-Type": "application/json" },
      },
    )
  }
})
