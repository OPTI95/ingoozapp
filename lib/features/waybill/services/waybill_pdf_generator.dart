import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';

import '../../../data/models/car_model.dart';
import '../../../data/models/waybill_model.dart';

// Загружаем шрифты с поддержкой кириллицы
Future<Map<String, pw.Font>> _loadPdfFonts() async {
  final regular = await rootBundle.load('assets/fonts/Arial.ttf');
  final bold = await rootBundle.load('assets/fonts/Arial Bold.ttf');
  final italic = await rootBundle.load('assets/fonts/Arial Italic.ttf');
  final boldItalic = await rootBundle.load('assets/fonts/Arial Bold Italic.ttf');
  
  return {
    'regular': pw.Font.ttf(regular),
    'bold': pw.Font.ttf(bold),
    'italic': pw.Font.ttf(italic),
    'boldItalic': pw.Font.ttf(boldItalic),
  };
}

// Стиль текста по умолчанию с нашим шрифтом
pw.TextStyle _textStyle({
  double fontSize = 8,
  bool isBold = false,
  bool isItalic = false,
  PdfColor? color,
  double? height,
  Map<String, pw.Font>? fonts,
}) {
  final fontStyle = isItalic ? pw.FontStyle.italic : pw.FontStyle.normal;
  if (fonts == null) {
    return pw.TextStyle(
      fontSize: fontSize,
      color: color,
      height: height,
      fontStyle: fontStyle,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  pw.Font? selectedFont;
  if (isBold && isItalic) {
    selectedFont = fonts['boldItalic'] ?? fonts['bold'] ?? fonts['italic'];
  } else if (isBold) {
    selectedFont = fonts['bold'];
  } else if (isItalic) {
    selectedFont = fonts['italic'] ?? fonts['regular'];
  } else {
    selectedFont = fonts['regular'];
  }

  return pw.TextStyle(
    fontSize: fontSize,
    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    font: selectedFont,
    color: color,
    height: height,
    fontStyle: fontStyle,
  );
}

pw.Widget _stampTextColumn(
  String text,
  Map<String, pw.Font> fonts, {
  double fontSize = 6,
  PdfColor color = const PdfColor.fromInt(0x1f4aa3),
}) {
  final lines = text.split('\n');
  return pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      for (var i = 0; i < lines.length; i++) ...[
        pw.Text(
          lines[i],
          textAlign: pw.TextAlign.center,
          style: _textStyle(
            fontSize: fontSize,
            fonts: fonts,
            color: color,
          ),
        ),
        if (i != lines.length - 1)
          pw.SizedBox(height: fontSize * 0.25),
      ],
    ],
  );
}

/// Генерирует PDF путевого листа, максимально близкий к официальному бланку.
Future<Uint8List> buildWaybillPdf({
  required WaybillModel waybill,
  Map<String, dynamic>? ownerZone,
  Map<String, dynamic>? zone4,
  String? driverName,
  CarModel? car,
}) async {
  final pdf = pw.Document();
  
  // Загружаем шрифты
  final fonts = await _loadPdfFonts();
  
  final z2 = ownerZone ?? <String, dynamic>{};
  final z4 = zone4 ?? <String, dynamic>{};

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _ownerTypeLabel(String? raw) {
    switch (raw) {
      case 'sole':
        return 'Индивидуальный предприниматель';
      case 'legal':
        return 'Юридическое лицо';
      case 'individual':
        return 'Физическое лицо';
      default:
        return '';
    }
  }

  final ownerTypeText = _ownerTypeLabel(z2['owner_type'] as String?);
  final ownerName = (z2['owner_name'] ?? '') as String;
  final ownerAddress = (z2['owner_address'] ?? '') as String;
  final ownerInn = (z2['owner_inn'] ?? '') as String;
  final ownerSnils = (z2['owner_snils'] ?? '') as String;
  final driverLicenseNumber = (z2['driver_license_number'] ?? '') as String;

  String _formatIsoDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return fmtDate(parsed);
      }
      return raw;
    }
    return '';
  }

  final driverLicenseValidFrom = _formatIsoDate(z2['driver_license_valid_from']);
  final driverLicenseValidTo = _formatIsoDate(z2['driver_license_valid_to']);

  final ownerLineParts = <String>[
    if (ownerTypeText.isNotEmpty) ownerTypeText,
    if (ownerName.isNotEmpty) ownerName,
    if (ownerAddress.isNotEmpty) ownerAddress,
    if (ownerInn.isNotEmpty) 'ИНН $ownerInn',
  ];
  final ownerLine = ownerLineParts.join(', ');

  String licenseDisplayName = '';
  String licenseOgrn = '';
  String licenseInn = '';
  String licenseAddress = '';
  String licensePhone = '';
  String licenseNumber = '';
  String licenseIssuedAt = '';
  String carDisplayName = '';
  String plateNumber = '';
  final licenseOkpo = (z2['license_okpo'] ?? '') as String;
  String licenseOkud = (z2['license_okud'] ?? '') as String;
  final techStampText = (z2['tech_stamp_text'] ?? '') as String;
  final medStampText = (z4['med_stamp_text'] ?? '') as String;
  final medStampFooter = (z4['med_stamp_footer'] ?? '') as String;

  if (car != null) {
    final base = car.licenseOrgName ?? '';
    switch (car.ownerType) {
      case OwnerType.soleProprietor:
        licenseDisplayName = 'Индивидуальный предприниматель $base';
        break;
      case OwnerType.legalEntity:
        licenseDisplayName = base.isNotEmpty
            ? 'Общество с Ограниченной Ответственностью\n"$base"'
            : 'Общество с Ограниченной Ответственностью';
        break;
      case OwnerType.individual:
        licenseDisplayName = base;
        break;
    }

    licenseOgrn = car.licenseOgrn ?? '';
    licenseInn = car.licenseInn ?? '';
    licenseAddress = car.licenseAddress ?? '';
    licensePhone = car.licensePhone ?? '';
    licenseNumber = car.licenseNumber ?? '';
    licenseIssuedAt = car.licenseIssuedAt != null ? fmtDate(car.licenseIssuedAt!) : '';
    carDisplayName = car.displayName;
    plateNumber = car.plateNumber;

    if (licenseOkud.isEmpty && (car.licenseOkud?.isNotEmpty ?? false)) {
      licenseOkud = car.licenseOkud!;
    }
  }

  String fmtTime(String time) {
    // ожидаем формат HH:MM или HH:MM:SS, отрезаем до минут
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

  String fmtClock(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  DateTime? startDateTime;
  final startParts = waybill.startTime.split(':');
  if (startParts.length >= 2) {
    final h = int.tryParse(startParts[0]);
    final m = int.tryParse(startParts[1]);
    if (h != null && m != null) {
      startDateTime = DateTime(waybill.startDate.year, waybill.startDate.month,
          waybill.startDate.day, h, m);
    }
  }

  final inspectionDateTime = startDateTime?.subtract(const Duration(minutes: 5));

  final mainTimeDisplay = fmtTime(waybill.startTime);
  String departureHour = '';
  String departureMinute = '';
  if (mainTimeDisplay.contains(':')) {
    final parts = mainTimeDisplay.split(':');
    departureHour = parts[0];
    if (parts.length > 1) departureMinute = parts[1];
  }

  String inspectionHour = '';
  String inspectionMinute = '';
  String inspectionTimeDisplay = '';
  String inspectionDateDisplay = fmtDate(waybill.endDate);
  if (inspectionDateTime != null) {
    inspectionTimeDisplay = fmtClock(inspectionDateTime);
    inspectionDateDisplay = fmtDate(inspectionDateTime);
    inspectionHour = inspectionDateTime.hour.toString().padLeft(2, '0');
    inspectionMinute = inspectionDateTime.minute.toString().padLeft(2, '0');
  }

  final mileageValue = waybill.mileage != null ? (waybill.mileage! - 44) : null;
  final mileageText = mileageValue != null ? '$mileageValue' : '';


  // Загружаем изображение бланка как фон страницы
  final bgData = await rootBundle.load('assets/waybill_blank.png');
  final bgImage = pw.MemoryImage(bgData.buffer.asUint8List());

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            // Фон — официальный бланк
            pw.Positioned.fill(
              child: pw.Image(bgImage, fit: pw.BoxFit.cover),
            ),

            // Примерная разметка основных полей поверх бланка.
            // При необходимости позиции можно будет тонко подогнать.

            // Номер путевого листа (в строке "серия №")
            pw.Positioned(
              top: 72,
              left: 262,
              child: pw.Text(
                waybill.number,
                style: _textStyle(fontSize: 10, isBold: true, fonts: fonts),
              ),
            ),

            // Дата начала/окончания
            pw.Positioned(
              top: 87,
              left: 225,
              child: pw.Text(
                fmtDate(waybill.startDate),
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            if (medStampText.isNotEmpty)
              pw.Positioned(
                top: 700,
                left: 109,
                child: pw.SizedBox(
                  width: 200,
                  child: pw.Text(
                    medStampText,
                    textAlign: pw.TextAlign.center,
                    style: _textStyle(
                      fontSize: 6.3,
                      fonts: fonts,
                      color: const PdfColor.fromInt(0x1f4aa3),
                    ),
                  ),
                ),
              ),

            if (medStampFooter.isNotEmpty)
              pw.Positioned(
                top: 754,
                left: 65,
                child: pw.SizedBox(
                  width: 200,
                  child: _stampTextColumn(
                    medStampFooter,
                    fonts,
                    fontSize: 6.9,
                    color: PdfColors.black,
                  ),
                ),
              ),

            // Организация (лицензиат) с префиксом по типу
            if (licenseDisplayName.isNotEmpty)
              pw.Positioned(
                top: 115,
                left: 130,
                child: pw.Text(
                  licenseDisplayName,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            // ОГРН / ИНН / ОКПО лицензиата
            pw.Positioned(
              top: 63,
              left: 81,
              child: pw.Text(
                licenseOgrn,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 75,
              left: 81,
              child: pw.Text(
                licenseInn,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 120,
              left: 517,
              child: pw.Text(
                licenseOkpo,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            if (licenseOkud.isNotEmpty)
              pw.Positioned(
                top: 98,
                left: 517,
                child: pw.Text(
                  licenseOkud,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            // Адрес и телефон лицензиата
            pw.Positioned(
              top: 147,
              left: 110,
              child: pw.Text(
                licenseAddress,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 124,
              left: 378,
              child: pw.Text(
                licensePhone,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            // Номер лицензии и дата выдачи
            pw.Positioned(
              top: 204,
              left: 333,
              child: pw.Text(
                licenseNumber,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 204,
              left: 375,
              child: pw.Text(
                licenseIssuedAt,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            if (techStampText.isNotEmpty)
              pw.Positioned(
                top: 292,
                left: 94,
                child: pw.SizedBox(
                  width: 230,
                  child: _stampTextColumn(
                    techStampText,
                    fonts,
                    fontSize: 5.65,
                  ),
                ),
              ),

            if (techStampText.isNotEmpty)
              pw.Positioned(
                top: 292,
                left: 373,
                child: pw.SizedBox(
                  width: 230,
                  child: _stampTextColumn(
                    techStampText,
                    fonts,
                    fontSize: 5.65,
                  ),
                ),
              ),

            // Марка/модель и госномер
            pw.Positioned(
              top: 159,
              left: 280,
              child: pw.Text(
                carDisplayName,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 170,
              left: 280,
              child: pw.Text(
                plateNumber,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 182,
              left: 517,
              child: pw.Text(
                plateNumber,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 170,
              left: 517,
              child: pw.Text(
                plateNumber,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 87,
              left: 370,
              child: pw.Text(
                inspectionDateDisplay,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
            if (inspectionTimeDisplay.isNotEmpty)
              pw.Positioned(
                top: 268,
                left: 525,
                child: pw.Text(
                  inspectionTimeDisplay,
                  style: _textStyle(fontSize: 9, fonts: fonts),
                ),
              ),

            if (inspectionDateDisplay.isNotEmpty)
              pw.Positioned(
                top: 246,
                left: 516,
                child: pw.Text(
                  inspectionDateDisplay,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            // Собственник (тип + ФИО + адрес + ИНН)
            if (ownerLine.isNotEmpty)
              pw.Positioned(
                top: 29,
                left: 145,
                child: pw.Text(
                  ownerLine,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            if (ownerSnils.isNotEmpty)
              pw.Positioned(
                top: 181,
                left: 335,
                child: pw.Text(
                  ownerSnils,
                  style: _textStyle(fontSize: 9, fonts: fonts),
                ),
              ),

            if (driverLicenseNumber.isNotEmpty)
              pw.Positioned(
                top: 193.5,
                left: 315,
                child: pw.Text(
                  driverLicenseNumber,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            if (driverLicenseValidFrom.isNotEmpty)
              pw.Positioned(
                top: 194,
                left: 375,
                child: pw.Text(
                  driverLicenseValidFrom,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            if (driverLicenseValidTo.isNotEmpty)
              pw.Positioned(
                top: 193.5,
                left: 433,
                child: pw.Text(
                  driverLicenseValidTo,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            // Дата и время выезда из парковочного места (зона 4)
            pw.Positioned(
              top: 238,
              left: 210,
              child: pw.Text(
                fmtDate(waybill.startDate),
                style: _textStyle(fontSize: 8, isBold: true, isItalic: true, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 251,
              left: 220,
              child: pw.Text(
                mainTimeDisplay,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            if (departureHour.isNotEmpty)
              pw.Positioned(
                top: 593,
                left: 351,
                child: pw.Text(
                  departureHour,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            if (departureMinute.isNotEmpty)
              pw.Positioned(
                top: 593,
                left: 370,
                child: pw.Text(
                  departureMinute,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),

            if (mileageText.isNotEmpty)
              pw.Positioned(
                top: 269,
                left: 150,
                child: pw.SizedBox(
                  width: 120,
                  child: pw.Center(
                    child: pw.Text(
                      mileageText,
                      style: _textStyle(fontSize: 8, fonts: fonts),
                    ),
                  ),
                ),
              ),

            // Время медосмотра (примерно в соответствующей ячейке зоны 4)

            pw.Positioned(
            top: 670,  // Adjust these coordinates as needed
            left: 205,  // Adjust these coordinates as needed
            child: pw.Text(
                () {
                final raw = z2['med_check_datetime'];
                if (raw is String && raw.isNotEmpty) {
                    try {
                    final dt = DateTime.parse(raw);
                    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
                    } catch (_) {
                    return '';
                    }
                }
                return '';
                }(),
                style: _textStyle(fontSize: 8, fonts: fonts),
            ),
            ),

            pw.Positioned(
              top: 683,
              left: 215,
              child: pw.Text(
                () {
                  final raw = z2['med_check_datetime'];
                  if (raw is String && raw.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(raw);
                      final h = dt.hour.toString().padLeft(2, '0');
                      final m = dt.minute.toString().padLeft(2, '0');
                      return '$h:$m';
                    } catch (_) {
                      return raw;
                    }
                  }
                  return '';
                }(),
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            // Водитель Ф.И.О. (используем driverName, если есть, иначе owner_name)
            pw.Positioned(
              top: 183,
              left: 145,
              child: pw.Text(
                (driverName != null && driverName.isNotEmpty)
                    ? driverName
                    : (z2['owner_name'] ?? '') as String,
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
