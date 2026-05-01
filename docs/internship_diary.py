from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT
import os

output_path = os.path.join(os.path.dirname(__file__), "Pregraduational_Internship_Diary.pdf")

doc = SimpleDocTemplate(
    output_path,
    pagesize=A4,
    topMargin=2 * cm,
    bottomMargin=2 * cm,
    leftMargin=2 * cm,
    rightMargin=2 * cm,
)

styles = getSampleStyleSheet()
title_style = ParagraphStyle("Title2", parent=styles["Normal"], fontSize=13, leading=16, alignment=TA_CENTER, spaceAfter=6, fontName="Helvetica-Bold")
label_style = ParagraphStyle("Label", parent=styles["Normal"], fontSize=10, leading=13, fontName="Helvetica-Bold")
value_style = ParagraphStyle("Value", parent=styles["Normal"], fontSize=10, leading=13, fontName="Helvetica")
body_style = ParagraphStyle("Body", parent=styles["Normal"], fontSize=10, leading=14, fontName="Helvetica", spaceAfter=4)
cell_style = ParagraphStyle("Cell", parent=styles["Normal"], fontSize=9, leading=12, fontName="Helvetica")
cell_bold = ParagraphStyle("CellB", parent=styles["Normal"], fontSize=9, leading=12, fontName="Helvetica-Bold")

elements = []

elements.append(Paragraph("Pregraduational Internship Diary", title_style))
elements.append(Spacer(1, 0.5 * cm))

info_data = [
    ["Student's name and surname:", "Maksat Saparbekuly"],
    ["Course:", "4"],
    ["ID:", "220103294"],
    ["Department:", "6B06101 - Information Systems"],
    ["Type of practice:", "Pregraduational Internship"],
]

info_table = Table(info_data, colWidths=[6.5 * cm, 10 * cm])
info_table.setStyle(TableStyle([
    ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
    ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
    ("FONTSIZE", (0, 0), (-1, -1), 10),
    ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ("TOPPADDING", (0, 0), (-1, -1), 2),
]))
elements.append(info_table)
elements.append(Spacer(1, 0.4 * cm))

confirm_text = (
    'Me, Maksat Saparbekuly, confirm that the internship period was completed in '
    'accordance with the work schedule of the internship from 26.01.2026 to 19.04.2026.'
)
elements.append(Paragraph(confirm_text, body_style))
elements.append(Spacer(1, 0.2 * cm))

elements.append(Paragraph("<b>Company name:</b> Payda Accounting Development", body_style))
elements.append(Spacer(1, 0.4 * cm))

tasks = [
    ("1", "Project onboarding: study of requirements, mobile app architecture design and development environment setup (Flutter, Supabase)", "26.01.2026", "01.02.2026"),
    ("2", "Database schema design, backend configuration and project structure setup", "02.02.2026", "08.02.2026"),
    ("3", "UI screens implementation: authentication pages, main dashboard and profile management", "09.02.2026", "15.02.2026"),
    ("4", "Navigation system, routing and reusable custom UI components development", "16.02.2026", "22.02.2026"),
    ("5", "Backend API integration: data models, repository layer and server communication", "22.02.2026", "01.03.2026"),
    ("6", "User authentication flows: email registration, password recovery and session management", "02.03.2026", "08.03.2026"),
    ("7", "Payment system integration: online payment gateway setup and transaction processing", "09.03.2026", "15.03.2026"),
    ("8", "Document generation module: PDF creation, form data processing and file management", "16.03.2026", "22.03.2026"),
    ("9", "New feature development: SMS authentication, promotional system and admin panel", "23.03.2026", "29.03.2026"),
    ("10", "Security implementation: data validation, error handling and access control", "30.03.2026", "05.04.2026"),
    ("11", "Performance optimization, bug fixing and UI/UX improvements based on user feedback", "06.04.2026", "12.04.2026"),
    ("12", "Testing, final improvements and deployment preparation for app store release", "13.04.2026", "19.04.2026"),
]

header = [
    Paragraph("<b>№</b>", cell_bold),
    Paragraph("<b>List of works to be performed (training)<br/>according to the program of diploma experience</b>", cell_bold),
    Paragraph("<b>Start</b>", cell_bold),
    Paragraph("<b>Finish</b>", cell_bold),
]

table_data = [header]
for num, desc, start, finish in tasks:
    table_data.append([
        Paragraph(num, cell_style),
        Paragraph(desc, cell_style),
        Paragraph(start, cell_style),
        Paragraph(finish, cell_style),
    ])

col_widths = [1 * cm, 10.5 * cm, 2.5 * cm, 2.5 * cm]
task_table = Table(table_data, colWidths=col_widths, repeatRows=1)
task_table.setStyle(TableStyle([
    ("GRID", (0, 0), (-1, -1), 0.5, colors.black),
    ("BACKGROUND", (0, 0), (-1, 0), colors.Color(0.9, 0.9, 0.9)),
    ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ("TOPPADDING", (0, 0), (-1, -1), 4),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ("LEFTPADDING", (0, 0), (-1, -1), 4),
    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
]))
elements.append(task_table)
elements.append(Spacer(1, 0.8 * cm))

elements.append(Paragraph("<b>Supervisor's grade:</b> _____ /40", body_style))

doc.build(elements)
print(f"PDF saved to: {output_path}")
