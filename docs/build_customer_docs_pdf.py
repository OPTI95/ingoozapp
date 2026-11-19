from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
DOCS_DIR = ROOT / "docs"
OUTPUT_PATH = DOCS_DIR / "Ingooz_Customer_Documentation.pdf"

FONT_REGULAR = ROOT / "assets" / "fonts" / "Arial.ttf"
FONT_BOLD = ROOT / "assets" / "fonts" / "Arial Bold.ttf"

pdfmetrics.registerFont(TTFont("IngoozArial", str(FONT_REGULAR)))
pdfmetrics.registerFont(TTFont("IngoozArialBold", str(FONT_BOLD)))

styles = getSampleStyleSheet()
title_style = ParagraphStyle(
    "Title",
    parent=styles["Normal"],
    fontName="IngoozArialBold",
    fontSize=18,
    leading=24,
    spaceAfter=12,
)
subtitle_style = ParagraphStyle(
    "Subtitle",
    parent=styles["Normal"],
    fontName="IngoozArialBold",
    fontSize=13,
    leading=18,
    textColor=colors.HexColor("#0B5CAB"),
    spaceBefore=8,
    spaceAfter=6,
)
body_style = ParagraphStyle(
    "Body",
    parent=styles["Normal"],
    fontName="IngoozArial",
    fontSize=10.5,
    leading=15,
    spaceAfter=4,
)
bullet_style = ParagraphStyle(
    "Bullet",
    parent=body_style,
    leftIndent=12,
    bulletIndent=0,
)

doc = SimpleDocTemplate(
    str(OUTPUT_PATH),
    pagesize=A4,
    leftMargin=2 * cm,
    rightMargin=2 * cm,
    topMargin=1.7 * cm,
    bottomMargin=1.7 * cm,
)

elements = []

elements.append(Paragraph("Ingooz — Техническая документация", title_style))
elements.append(
    Paragraph(
        "Версия документа: актуально на момент сборки.",
        body_style,
    )
)
elements.append(Spacer(1, 0.3 * cm))

elements.append(Paragraph("1) Описание базы данных (ER-модель)", subtitle_style))
elements.append(
    Paragraph(
        "Ключевые сущности: users/auth, profiles, cars, waybills, payments, "
        "promo_codes, promo_redemptions, stamps, guide_files, phone_otps.",
        body_style,
    )
)
for line in [
    "profiles связана 1:1 с auth.users по user_id.",
    "cars и waybills связаны с пользователем через user_id.",
    "waybills дополнительно связана с cars через car_id.",
    "payments хранит операции пополнений и статусы эквайринга.",
    "promo_redemptions связывает пользователя и промокод.",
    "phone_otps — техническая таблица OTP для phone auth (uCaller).",
]:
    elements.append(Paragraph(line, bullet_style, bulletText="•"))

elements.append(Spacer(1, 0.2 * cm))
table_data = [
    ["Таблица", "Назначение"],
    ["profiles", "Профиль пользователя, баланс, роль администратора"],
    ["cars", "Данные ТС, собственника и лицензии"],
    ["waybills", "Путевые листы и зоны печатной формы"],
    ["payments", "История и статусы платежей"],
    ["promo_codes / promo_redemptions", "Промокоды и их активации"],
    ["guide_files", "PDF-контент памятки"],
    ["stamps", "Тексты печатей и цена путевого листа"],
    ["phone_otps", "Коды подтверждения по телефону"],
]
tbl = Table(table_data, colWidths=[5.2 * cm, 10.8 * cm])
tbl.setStyle(
    TableStyle(
        [
            ("FONTNAME", (0, 0), (-1, 0), "IngoozArialBold"),
            ("FONTNAME", (0, 1), (-1, -1), "IngoozArial"),
            ("FONTSIZE", (0, 0), (-1, -1), 9.5),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#EAF3FF")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#C8D7EA")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 6),
            ("RIGHTPADDING", (0, 0), (-1, -1), 6),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ]
    )
)
elements.append(tbl)

elements.append(Spacer(1, 0.35 * cm))
elements.append(Paragraph("2) Структура и основные модули приложения", subtitle_style))
for line in [
    "lib/core: роутинг, тема, конфигурация окружения.",
    "lib/features/auth: email/phone авторизация, регистрация, восстановление пароля.",
    "lib/features/waybill: создание, просмотр, PDF, админ-поиск путевых листов.",
    "lib/features/payments: пополнение баланса через Tinkoff.",
    "lib/features/promo: применение и администрирование промокодов.",
    "lib/features/info: памятка (PDF), контакты.",
    "supabase/functions: sms-auth, tinkoff-init, tinkoff-notify, email-change.",
]:
    elements.append(Paragraph(line, bullet_style, bulletText="•"))

elements.append(Spacer(1, 0.35 * cm))
elements.append(Paragraph("3) Инструкция администратора (контент и покупки)", subtitle_style))
for line in [
    "Админ-доступ: profiles.is_admin = true.",
    "Контент: раздел «Памятка» (/guide) — загрузка/удаление PDF файлов.",
    "Покупки: /payment-methods, платежи через tinkoff-init и webhook tinkoff-notify.",
    "Промокоды: /admin-promo — создание, редактирование, деактивация, удаление.",
    "Печати/цены: /admin-stamps — тексты печатей, ОКПО, цена путевого листа.",
]:
    elements.append(Paragraph(line, bullet_style, bulletText="•"))

elements.append(Spacer(1, 0.35 * cm))
elements.append(Paragraph("4) Актуальные исходники дизайна", subtitle_style))
for line in [
    "В репозитории есть: assets/icons/app_icons.png (иконка приложения).",
    "Есть продуктовые скриншоты: docs/screenshots/1-login.png ... 5-waybill-pdf.png.",
    "Сгенерированные иконки платформ: android mipmap + iOS AppIcon.appiconset.",
    "Файлов формата .fig / .sketch / .xd / .psd / .ai в репозитории нет.",
]:
    elements.append(Paragraph(line, bullet_style, bulletText="•"))

elements.append(Spacer(1, 0.45 * cm))
doc.build(elements)
print(f"PDF saved to: {OUTPUT_PATH}")
