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
  
  return {
    'regular': pw.Font.ttf(regular),
    'bold': pw.Font.ttf(bold),
  };
}

// Стиль текста по умолчанию с нашим шрифтом
pw.TextStyle _textStyle({
  double fontSize = 8, 
  bool isBold = false,
  Map<String, pw.Font>? fonts,
}) {
  if (fonts == null) {
    return pw.TextStyle(fontSize: fontSize);
  }
  
  return pw.TextStyle(
    fontSize: fontSize,
    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    font: isBold ? fonts['bold'] : fonts['regular'],
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

  String licenseDisplayName = '';
  if (car != null) {
    final base = car.licenseOrgName ?? '';
    switch (car.ownerType) {
      case OwnerType.soleProprietor:
        licenseDisplayName = 'Индивидуальный предприниматель $base';
        break;
      case OwnerType.legalEntity:
        licenseDisplayName = 'Юридическое лицо $base';
        break;
      case OwnerType.individual:
        licenseDisplayName = base;
        break;
    }
  }

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String fmtTime(String time) {
    // ожидаем формат HH:MM или HH:MM:SS, отрезаем до минут
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

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

            // Организация (лицензиат) с префиксом по типу
            if (licenseDisplayName.isNotEmpty)
              pw.Positioned(
                  top: 29,
                left: 140,
                child: pw.Text(
                  licenseDisplayName,
                  style: _textStyle(fontSize: 8, fonts: fonts),
                ),
              ),
            pw.Positioned(
              top: 87,
              left: 370,
              child: pw.Text(
                fmtDate(waybill.endDate),
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            // Собственник (ФИО / наименование)
            // pw.Positioned(
            //   top: 145,
            //   left: 110,
            //   child: pw.Text(
            //     (z2['owner_name'] ?? '') as String,
            //     style: _textStyle(fontSize: 8).copyWith(font: font),
            //   ),
            // ),

            // ИНН собственника
            // pw.Positioned(
            //   top: 160,
            //   left: 110,
            //   child: pw.Text(
            //     (z2['owner_inn'] ?? '') as String,
            //     style: _textStyle(fontSize: 8).copyWith(font: font),
            //   ),
            // ),

            // Адрес собственника
            // pw.Positioned(
            //   top: 175,
            //   left: 110,
            //   child: pw.Text(
            //     (z2['owner_address'] ?? '') as String,
            //     style: _textStyle(fontSize: 8).copyWith(font: font),
            //   ),
            // ),

            // Телефон собственника
            // pw.Positioned(
            //   top: 190,
            //   left: 110,
            //   child: pw.Text(
            //     (z2['owner_phone'] ?? '') as String,
            //     style: _textStyle(fontSize: 8).copyWith(font: font),
            //   ),
            // ),

            // Дата и время выезда из парковочного места (зона 4)
            pw.Positioned(
              top: 238,
              left: 205,
              child: pw.Text(
                fmtDate(waybill.startDate),
                style: _textStyle(fontSize: 8, isBold: true, fonts: fonts),
              ),
            ),
            pw.Positioned(
              top: 251,
              left: 215,
              child: pw.Text(
                fmtTime(waybill.startTime),
                style: _textStyle(fontSize: 8, fonts: fonts),
              ),
            ),

            // Время медосмотра (примерно в соответствующей ячейке зоны 4)
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
