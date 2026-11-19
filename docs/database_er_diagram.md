# Ingooz — База данных (ER)

Документ составлен по текущему коду Flutter и SQL-файлам в репозитории.  
Ниже — практическая диаграмма сущностей и связей, используемых приложением.

## ER-диаграмма

```mermaid
erDiagram
  AUTH_USERS ||--o| PROFILES : "user_id -> id"
  AUTH_USERS ||--o{ CARS : "cars.user_id"
  AUTH_USERS ||--o{ WAYBILLS : "waybills.user_id"
  AUTH_USERS ||--o{ PAYMENTS : "payments.user_id"
  AUTH_USERS ||--o{ GUIDE_FILES : "guide_files.uploaded_by"
  AUTH_USERS ||--o{ PROMO_REDEMPTIONS : "promo_redemptions.user_id"

  CARS ||--o{ WAYBILLS : "waybills.car_id -> cars.id"
  PROMO_CODES ||--o{ PROMO_REDEMPTIONS : "promo_redemptions.promo_code_id -> promo_codes.id"

  AUTH_USERS {
    uuid id PK
    text email
    text phone
    jsonb user_metadata
    timestamptz created_at
  }

  PROFILES {
    uuid user_id PK,FK
    text full_name
    text phone
    numeric balance
    bool is_admin
    int waybill_quota
  }

  CARS {
    uuid id PK
    uuid user_id FK
    text display_name
    text plate_number
    text owner_type
    text owner_name
    text owner_inn
    text owner_address
    text owner_phone
    text vin
    text sts_number
    text insurance_number
    text license_org_name
    text license_type
    text license_type_other_label
    text license_number
    text license_inn
    text license_okud
    timestamptz license_issued_at
  }

  WAYBILLS {
    uuid id PK
    uuid user_id FK
    uuid car_id FK
    text number
    date start_date
    date end_date
    text start_time
    int mileage
    jsonb zone2
    jsonb zone3
    jsonb zone4
    bool is_consumed
    timestamptz created_at
  }

  PAYMENTS {
    uuid id PK
    uuid user_id FK
    int amount
    text currency
    text status
    text provider
    text provider_payment_id
    timestamptz created_at
    timestamptz updated_at
  }

  PROMO_CODES {
    uuid id PK
    text code
    int waybill_quota
    int max_redemptions
    int redemptions_count
    bool is_active
    timestamptz expires_at
    timestamptz created_at
  }

  PROMO_REDEMPTIONS {
    uuid id PK
    uuid user_id FK
    uuid promo_code_id FK
    timestamptz redeemed_at
  }

  STAMPS {
    text key PK
    text value
  }

  GUIDE_FILES {
    uuid id PK
    text file_name
    text file_base64
    uuid uploaded_by FK
    timestamptz created_at
  }

  PHONE_OTPS {
    uuid id PK
    text phone
    text code
    bool verified
    int attempts
    int call_count
    text ucaller_id
    timestamptz last_call_at
    timestamptz expires_at
    timestamptz created_at
  }
```

## Назначение таблиц

- `profiles` — профиль пользователя, роль администратора, баланс, квота путевых листов.
- `cars` — транспорт пользователя и реквизиты собственника/лицензиата.
- `waybills` — путевые листы, включая зоны печатной формы (`zone2`, `zone3`, `zone4`).
- `payments` — операции пополнения (Tinkoff), статусы оплаты.
- `promo_codes`, `promo_redemptions` — промокоды и факты их активации пользователями.
- `stamps` — админ-настройки печатей и цена путевого листа (`key/value`).
- `guide_files` — PDF-файлы памятки, загружаемые администратором.
- `phone_otps` — техническая таблица OTP для телефонной авторизации (uCaller).

## Примечания

- Для `phone_otps` в проекте есть SQL с RLS (только `service_role` через Edge Function).
- Часть ограничений/политик для остальных таблиц управляется на стороне Supabase проекта и должна проверяться отдельно через SQL Editor/Policies.
