# Edge Functions: Тинькофф эквайринг

## Проблема 403 Forbidden

Тинькофф (T-Bank) для части API требует **статический IP** в whitelist. У **Supabase Edge Functions** статического egress IP нет (они работают на Deno Deploy с динамическими IP), поэтому запросы к Тинькофф могут возвращать **HTTP 403 Forbidden**, даже при корректных ключах и подписи.

## Решения

### 1. Отключить проверку IP у Тинькофф (предпочтительно)

Для **T-API** (портал разработчика) проверку IP можно отключить:

- Написать на **openapi@tbank.ru** с указанием **ИНН компании**.
- Либо обратиться в чат или на горячую линию Т-Бизнеса.
- После отключения перевыпустить токен; при вводе IP можно указать, например, `0.0.0.0`.

Уточните у поддержки, применимо ли это к **эквайрингу** (Init/rest-api-test / securepay). Если да — после отключения проверки IP Edge Function будет работать без прокси.

### 2. Прокси со статическим IP

Если отключить проверку IP нельзя, запросы к Тинькофф нужно отправлять с хоста с **фиксированным IP**:

1. Развернуть прокси из папки **`supabase/tinkoff-proxy/`** на сервере с статическим IP (VPS, Fly.io, Railway и т.п.). Инструкция — в `supabase/tinkoff-proxy/README.md`.
2. Добавить этот IP в whitelist в личном кабинете Тинькофф.
3. В Supabase задать секреты:
   - `TINKOFF_PROXY_URL` — URL прокси, например `https://your-proxy.example.com`
   - `TINKOFF_PROXY_SECRET` — (опционально) секрет в заголовке `X-Proxy-Secret` для доступа к прокси

После этого Edge Function `tinkoff-init` будет слать запрос Init через прокси, а не напрямую в Тинькофф.

## URL и окружения Тинькофф

Документация: [Init — developer.tbank.ru/eacq/api/init](https://developer.tbank.ru/eacq/api/init).

- **Тест:** `TINKOFF_API_BASE=https://rest-api-test.tinkoff.ru`  
  Endpoint Init: `https://rest-api-test.tinkoff.ru/v2/Init`
- **Боевая (реальные платежи):** `TINKOFF_API_BASE=https://securepay.tinkoff.ru`  
  Endpoint Init: `https://securepay.tinkoff.ru/v2/Init`

Ошибка **403** со стороны Тинькофф означает, что запрос ушёл в **тестовую** среду. Для реальных платежей обязательно используйте боевой URL и ключи боевого терминала. Ключи тестового и боевого терминала разные.

**Ошибка 400 «Неверные параметры»:** запрос доходит до Тинькофф, но параметры отклонены. Проверьте: (1) `TINKOFF_API_BASE` и ключи соответствуют одной среде (тест или боевая); (2) в секретах SuccessURL/FailURL/NotificationURL — валидные URL (`https://...` или `http://...`); (3) в ответе может быть поле `errorCode` — сверьте с [кодами ошибок Тинькофф](https://developer.tbank.ru/eacq/errors).

## Секреты (Supabase Dashboard → Edge Functions → Secrets)

| Секрет | Обязательный | Описание |
|--------|---------------|----------|
| `TINKOFF_TERMINAL_KEY` | да | Ключ терминала |
| `TINKOFF_PASSWORD` | да | Пароль терминала |
| `TINKOFF_API_BASE` | да | Базовый URL (тест или боевой, см. выше) |
| `TINKOFF_SUCCESS_URL` | нет | URL успешной оплаты |
| `TINKOFF_FAIL_URL` | нет | URL неуспешной оплаты |
| `TINKOFF_NOTIFY_URL` | нет | URL для нотификаций (webhook) |
| `TINKOFF_PROXY_URL` | нет | URL прокси (если используете вариант 2) |
| `TINKOFF_PROXY_SECRET` | нет | Секрет для доступа к прокси |

## Локальный запуск

```bash
supabase start
supabase functions serve tinkoff-init --env-file .env.local
```

В `.env.local` задайте те же переменные, что и в Dashboard (включая при необходимости `TINKOFF_PROXY_URL` и `TINKOFF_PROXY_SECRET`).
