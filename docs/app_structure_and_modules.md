# Ingooz — Структура и основные модули

## Технологический стек

- Клиент: Flutter (`lib/`)
- Backend: Supabase (Postgres + Auth + Edge Functions)
- Платежи: Tinkoff (`tinkoff-init`, `tinkoff-notify`)
- Телефонная авторизация: uCaller (`sms-auth`)

## Структура проекта (основное)

- `lib/main.dart` — инициализация Supabase, deep links, запуск приложения.
- `lib/core/`
  - `router/app_router.dart` — маршрутизация и deep-link сценарии.
  - `theme/app_theme.dart` — тема.
  - `config/env.dart` — чтение конфигурации окружения.
- `lib/data/`
  - `models/` — модели домена (`CarModel`, `WaybillModel`, `PaymentModel`, и др.).
  - `repositories/` — доступ к данным (Supabase запросы по модулям).
- `lib/features/`
  - `auth/` — авторизация/регистрация/email recovery/phone auth.
  - `home/` — главная страница и быстрые действия.
  - `cars/` — список/редактирование автомобилей.
  - `waybill/` — создание, просмотр и PDF путевого листа + админ-поиск.
  - `payments/` — пополнение баланса через Tinkoff.
  - `promo/` — применение промокодов и админка промокодов.
  - `info/` — памятка (PDF-материалы) и контакты.
  - `admin/` — админ-настройки штампов/цен.
- `supabase/functions/`
  - `sms-auth` — OTP-флоу с uCaller.
  - `tinkoff-init` — старт платежа.
  - `tinkoff-notify` — webhook статусов платежа.
  - `email-change` — сценарии смены email.

## Основные бизнес-модули

### 1) Авторизация и аккаунт

- Email login/signup/reset password.
- Phone login/signup/reset через `sms-auth`.
- Для новых phone-пользователей — обязательная установка пароля.

### 2) Профиль и баланс

- Таблица `profiles` хранит ФИО, телефон, баланс, роль `is_admin`.
- Баланс используется для списания стоимости путевых листов.

### 3) Автомобили

- Пользователь хранит набор машин (`cars`) с данными собственника/лицензиата.

### 4) Путевые листы

- Создание путевых листов (`waybills`) с зонами данных для печатной формы.
- Генерация PDF и просмотр/открытие в приложении.
- Админ-панель поиска по номеру и владельцу.

### 5) Оплата

- Инициализация платежа через Edge Function `tinkoff-init`.
- Обновление статуса и баланса через webhook `tinkoff-notify`.

### 6) Промокоды

- Пользователь активирует промокод, получает дополнительную квоту.
- Админ может создавать/редактировать/деактивировать/удалять промокоды.

### 7) Контент «Памятка»

- Админ загружает PDF в `guide_files`.
- Пользователи просматривают/шарят документы.

## Маршруты (ключевые)

- Auth: `/`, `/sign-up`, `/forgot-password`, `/reset-password`, `/phone-sign-in`, `/phone-sign-up`, `/phone-reset-password`
- Main: `/home`, `/profile`, `/cars`, `/waybill`, `/payment-methods`, `/promo`, `/guide`
- Admin: `/admin-waybills`, `/admin-promo`, `/admin-stamps`

## Роли доступа

- Обычный пользователь: базовые пользовательские экраны.
- Администратор (`profiles.is_admin = true`): доступ к админ-модулям.
