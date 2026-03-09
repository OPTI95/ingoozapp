# Tinkoff proxy (статический IP)

Прокси для запросов к Тинькофф API. Разверните на хосте с **статическим IP**, добавьте этот IP в whitelist Тинькофф, затем укажите URL прокси в секрете Edge Function `TINKOFF_PROXY_URL`.

## Запуск локально

```bash
cd supabase/tinkoff-proxy
export TINKOFF_PROXY_SECRET=your-secret   # опционально
deno run --allow-net --allow-env index.ts
```

Порт по умолчанию: 8080. Переменная `PORT` — при необходимости.

## Деплой (пример: Fly.io)

1. Установите [flyctl](https://fly.io/docs/hands-on/install-flyctl/).
2. В папке `supabase/tinkoff-proxy`:

```bash
fly launch --no-deploy
# Укажите регион, имя приложения.
# В fly.toml можно задать [env] PORT = "8080".
```

3. Получите статический IP и привяжите к приложению:

```bash
fly ips allocate-v4
```

4. Задайте секрет и задеплойте:

```bash
fly secrets set TINKOFF_PROXY_SECRET=your-secret
fly deploy
```

5. В Supabase (Edge Functions → Secrets):

- `TINKOFF_PROXY_URL` = `https://your-app.fly.dev`
- `TINKOFF_PROXY_SECRET` = тот же `your-secret`

6. В личном кабинете Тинькофф добавьте выделенный IPv4 в whitelist.

## Протокол

- **POST** с телом `{ "url": "https://rest-api-test.tinkoff.ru/rest/Init", "body": { ... } }`.
- Заголовок `X-Proxy-Secret` (если задан `TINKOFF_PROXY_SECRET`) — для авторизации.
- Прокси делает POST `body` на `url` и возвращает ответ Тинькофф без изменений.

Разрешены только хосты: `rest-api-test.tinkoff.ru`, `securepay.tinkoff.ru`.
