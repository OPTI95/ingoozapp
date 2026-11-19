# Миграция на чистую архитектуру (Dio + JWT + BLoC)

Бэкенд переехал с **Supabase** на **Django REST API (`/api/v1/...`, JWT)**.
Этот документ фиксирует целевую архитектуру и чек-лист оставшихся фич.

## Стек
- **flutter_bloc / bloc** — бизнес-логика (по фиче свой Bloc)
- **get_it** — DI (`lib/core/di/injection.dart`)
- **dio + pretty_dio_logger** — сеть и логирование запросов
- **flutter_secure_storage** — хранение JWT (`access` / `refresh`)
- **logger** — логирование (`AppLogger`)
- **equatable** — сравнение сущностей/состояний

## Слои (на примере каждой фичи)
```
lib/features/<feature>/
  domain/
    entities/        # чистые сущности (Equatable), без JSON
    repositories/    # абстрактный контракт (throws Failure)
  data/
    models/          # extends entity + fromJson/toJson
    datasources/     # *RemoteDataSource — голые вызовы Dio, throws AppException
    repositories/    # *RepositoryImpl — маппит ошибки в Failure, пишет в storage
  presentation/
    bloc/            # <feature>_bloc.dart + _event.dart + _state.dart
    pages/           # экраны, общаются ТОЛЬКО с Bloc
```

**Поток данных:** UI → `Bloc` (event) → `Repository` (domain) → `RepositoryImpl` →
`RemoteDataSource` (Dio) → API. Ошибки: `DioException` → `AppException`
(`exceptionFromDio`) → `Failure` (`failureFromException`) → состояние `*Error`.

## Ядро (уже готово)
- `core/config/env.dart` — `Env.apiBaseUrl` (читается из `.env` → `API_BASE_URL`)
- `core/network/dio_client.dart` — единый `Dio` с интерсепторами
- `core/network/interceptors/auth_interceptor.dart` — Bearer + авто-refresh при 401
- `core/network/api_endpoints.dart` — все пути API
- `core/storage/token_storage.dart` — JWT в secure storage
- `core/error/{exceptions,failure,error_mapper}.dart` — типизированные ошибки
- `core/logging/app_logger.dart` — `AppLogger`
- `core/di/injection.dart` — регистрация зависимостей (`sl`)

> ⚠️ Впиши реальный адрес API в `.env`: `API_BASE_URL=https://...`

## Эталон: фича `auth` (готова)
Покрывает: `request-code`, `verify-code`, `token`, `token/refresh`, `profile` (для текущего юзера).
Экран `phone_sign_in_page.dart` переведён на `AuthBloc`. Файлы — образец для остальных фич.

---

## Чек-лист фич
✅ Все фичи, покрытые API, мигрированы: auth, profile, vehicles, waybills,
billing, promo, guide.

- [x] **profile** — ✅ готово. `GET /profile/`, `PATCH /profile/`.
  - экран `profile_page.dart` переведён на `ProfileBloc`.
  - `security_settings_page.dart` — НЕ мигрирован (смена email/пароля нет в API).
- [x] **vehicles** — ✅ готово. `GET/POST /vehicles/`, `PUT/DELETE /vehicles/{id}/`.
  - экраны `cars_list_page.dart` (→ `VehiclesBloc`), `car_form_page.dart` (→ `VehicleFormBloc`).
  - новая сущность `Vehicle` + свой `OwnerType` (в `vehicles/domain/entities/`).
  - ⚠️ старые `data/models/car_model.dart` и `data/repositories/car_repository.dart`
    оставлены: `CarModel`/`OwnerType` ещё нужны немигрированным экранам waybill.
    `car_repository.dart` теперь не используется (можно удалить после миграции waybills).
- [x] **waybills** — ✅ готово. `GET /waybills/`, `GET /waybills/{id}/`, `POST /waybills/issue/`.
  - новая фича в `features/waybills/` (домен/data/presentation), роут `/waybill` → `WaybillsPage`.
  - `WaybillsBloc` (история), `WaybillIssueBloc` (выбор авто + выпуск, тянет авто через
    `VehicleRepository`), экраны: список / выпуск / детали (открытие `pdf_url` через url_launcher).
  - ⚠️ UX упрощён: сервер сам генерирует номер/даты/стоимость/PDF, поэтому старая
    клиентская форма (822 стр.) и PDF-генератор больше не нужны. Старые файлы в
    `features/waybill/` (`waybill_page/form/view/pdf_preview`, `services/waybill_pdf_generator`)
    оставлены как legacy и больше не используются (кроме `waybill_admin_panel_page` — он всё ещё
    на роуте `/admin-waybills`).
  - после этой миграции `data/models/car_model.dart` всё ещё нужен legacy-файлам waybill.
- [x] **payments / billing** — ✅ готово. `GET /balance/`, `GET /payments/`,
    `POST /payments/create/`, `GET /transactions/`.
  - фича `features/billing/`: сущности Balance/Payment/BalanceTransaction,
    `BillingRepository` (balance/payments/create/transactions), `TopUpBloc`.
  - экран `payment_method_page.dart` переведён на `TopUpBloc`: показывает баланс,
    создаёт платёж → открывает `payment_url` в браузере (статус обновляет вебхук на сервере).
  - ⚠️ убран старый Tinkoff/Supabase-realtime flow. Старые `data/repositories/payment_repository.dart`
    и `data/models/payment_model.dart` оставлены — нужны legacy-экранам waybill.
  - история платежей/транзакций в репозитории есть, отдельного экрана пока нет (можно добавить).
- [x] **promo** — ✅ готово. `POST /promo/apply/`, `GET /promo/redemptions/`.
  - фича `features/promo/`: `PromoRedemption`, `PromoRepository` (apply/redemptions),
    `PromoBloc` (счётчик из профиля + история + активация).
  - экран `promo_page.dart` переведён на `PromoBloc` (счётчик подарочных листов берётся
    из `ProfileRepository.promoWaybillsLeft`).
  - ⚠️ убрано Supabase-гейтирование по заполненности профиля — теперь полагаемся на ошибки бэкенда.
  - `promo_admin_page.dart` (админка) — НЕ мигрирован (в API нет), остаётся на старом
    `data/repositories/promo_repository.dart`.
- [x] **guide** — ✅ готово. `GET /guide/`.
  - фича `features/guide/`: `GuideFile` (title, file_url, order), `GuideRepository`, `GuideBloc`.
  - экран `guide_page.dart` переведён на `GuideBloc` (read-only): список документов,
    открытие `file_url` через url_launcher.
  - ⚠️ убраны админская загрузка/удаление PDF и base64-хранение (в API только чтение).
    Старая `data/models/guide_file.dart` больше не используется.

## НЕ мигрируем (нет в API) — оставлены как есть
email/Google/WhatsApp-вход, регистрация по email, подтверждение/смена email,
сброс пароля по email, админка промокодов (`promo_admin_page.dart`),
печати (`stamps_settings_page.dart`), админ-панель путевых
(`waybill_admin_panel_page.dart`). Эти экраны используют старый Supabase-код.
