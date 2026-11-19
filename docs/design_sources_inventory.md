# Ingooz — Актуальные исходники дизайна

Ниже перечислено, что реально присутствует в репозитории на текущий момент.

## 1) Доступные дизайн-материалы в проекте

### Иконка приложения

- `assets/icons/app_icons.png` — исходник иконки для генерации launcher icons.

### Скриншоты продукта

- `docs/screenshots/1-login.png`
- `docs/screenshots/2-home.png`
- `docs/screenshots/3-payment.png`
- `docs/screenshots/4-waybill-form.png`
- `docs/screenshots/5-waybill-pdf.png`

### Платформенные иконки (сгенерированные)

- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`

## 2) Чего нет в репозитории

В текущем репозитории **не найдены** исходники форматов:

- `.fig` (Figma export)
- `.xd`
- `.sketch`
- `.psd`
- `.ai`

То есть сейчас в git лежат в основном растровые ассеты и скриншоты, а не полноценный дизайн-макет.

## 3) Что передать заказчику как “актуальные исходники дизайна”

Минимальный пакет прямо сейчас:

1. `assets/icons/app_icons.png`
2. `docs/screenshots/*.png`
3. Пояснение, что master-макет (Figma/Sketch) хранится вне репозитория (если он есть у дизайнера).

## 4) Рекомендуемое улучшение

Чтобы в будущем не терять дизайн-исходники, добавить в репозиторий:

- ссылку на основной Figma-файл в отдельный `docs/design_links.md`,
- версионируемые экспорт-пакеты экранов (например, `docs/design_exports/vYYYY-MM-DD/`).
