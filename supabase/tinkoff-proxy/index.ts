/**
 * Tinkoff proxy: forwards Init (and other) requests from Supabase Edge Function
 * to Tinkoff API. Deploy on a host with static IP and add that IP to Tinkoff whitelist.
 *
 * Run: deno run --allow-net --allow-env index.ts
 * Deploy: e.g. Fly.io, Railway, or any VPS with static IP.
 */

const PROXY_SECRET = Deno.env.get("TINKOFF_PROXY_SECRET")
const PORT = parseInt(Deno.env.get("PORT") ?? "8080", 10)

async function handle(req: Request): Promise<Response> {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 })
  }

  if (PROXY_SECRET) {
    const secret = req.headers.get("X-Proxy-Secret")
    if (secret !== PROXY_SECRET) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }
  }

  let payload: { url?: string; body?: Record<string, unknown> }
  try {
    payload = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }

  const { url, body } = payload
  if (!url || typeof url !== "string" || !body || typeof body !== "object") {
    return new Response(
      JSON.stringify({ error: "Missing or invalid url/body" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    )
  }

  // Only allow Tinkoff hosts
  const allowedHosts = [
    "rest-api-test.tinkoff.ru",
    "securepay.tinkoff.ru",
  ]
  const targetHost = new URL(url).hostname
  if (!allowedHosts.includes(targetHost)) {
    return new Response(JSON.stringify({ error: "URL not allowed" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    })
  }

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "IngoozApp-Tinkoff-Proxy/1.0",
      },
      body: JSON.stringify(body),
    })
    const text = await res.text()
    return new Response(text, {
      status: res.status,
      headers: { "Content-Type": res.headers.get("Content-Type") ?? "application/json" },
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : "Unknown error"
    return new Response(
      JSON.stringify({ error: "Proxy fetch failed", detail: message }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    )
  }
}

Deno.serve({ port: PORT }, handle)
