import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ingoozapp/core/theme/app_colors.dart';
import 'package:printing/printing.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/waybill.dart';
import 'waybill_pdf_page.dart';

/// "Просмотр путевого листа" — zoned view of the issued waybill that mirrors
/// the printable PDF layout. The PDF icon in the AppBar opens the in-app
/// viewer; "Сохранить в файлы" downloads the PDF and shares it to the
/// system file picker.
class WaybillDetailPage extends StatefulWidget {
  const WaybillDetailPage({super.key, required this.waybill});

  final Waybill waybill;

  @override
  State<WaybillDetailPage> createState() => _WaybillDetailPageState();
}

class _WaybillDetailPageState extends State<WaybillDetailPage> {
  bool _saving = false;

  // --- formatters ---

  static String _isoDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String _ruDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static String _timeHms(DateTime? d) {
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  }

  static String _timeHm(DateTime? d) {
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  Waybill get _w => widget.waybill;
  bool get _isPromo => _w.paymentSource == 'promo';

  String get _filename =>
      'waybill-${_w.number.isNotEmpty ? _w.number : _w.id}.pdf';

  void _openPdf() {
    if (!_w.hasPdf) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WaybillPdfPage(waybill: _w)),
    );
  }

  Future<bool> _confirmPromoDeduction() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Подтверждение списания',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Будет списан 1 подарочный лист.\n\n'
          'Списание произойдёт при открытии/сохранении PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _saveToFiles() async {
    final url = _w.pdfUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF недоступен')),
      );
      return;
    }
    if (_isPromo && !await _confirmPromoDeduction()) return;
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final res = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      await Printing.sharePdf(bytes: bytes, filename: _filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Просмотр путевого листа'),
        actions: [
          if (_w.hasPdf)
            IconButton(
              icon: SvgPicture.asset(
                'assets/svg/sp.svg',
                width: 22,
                height: 22,
              ),
              tooltip: 'Открыть PDF',
              onPressed: _openPdf,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // Header.
                Text(
                  '№ ${_w.number}',
                  style: const TextStyle(
                    fontSize: 26,
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _inline('Дата:', _isoDate(_w.issuedAt)),
                    _inline('Время выезда:', _timeHms(_w.startTime)),
                  ],
                ),
                const SizedBox(height: 2),
                if (_w.odometer != null)
                  _inline('Пробег при выезде:', '${_w.odometer} км'),

                const SizedBox(height: 16),
                _title('Зона 1. Собственник (владелец) ТС'),
                _row('Тип:', _w.ownerType),
                _row('ФИО / наименование:', _w.ownerFullName),
                _row('Адрес:', _w.ownerAddress),

                const SizedBox(height: 12),
                _row('Водитель Ф.И.О.:', _w.driverFullName),

                const SizedBox(height: 16),
                _title('Организация (лицензиат)'),
                _row(
                  'Наименование:',
                  _w.licenseeName ?? _w.licensee,
                ),
                _row('ОГРН / ОГРНИП:', _w.licenseeOgrn ?? '-'),
                _row('ИНН:', _w.licenseeInn ?? '-'),
                _row('ОКПО:', _w.licenseeOkpo ?? '-'),
                _row('ОКУД:', _w.licenseeOkud ?? '-'),
                _row('Адрес:', _w.licenseeAddress ?? '-'),
                _row('Телефон:', _w.licenseePhone ?? '-'),
                _row('Номер лицензии:', _w.licenseeLicenseNumber ?? '-'),
                _row('Лицензия "С":', _ruDate(_w.licenseeLicenseIssuedAt)),

                const SizedBox(height: 16),
                _title('Зона 4. Время выезда и медосмотра'),
                _row('Время выезда:', _timeHm(_w.startTime)),
                _row(
                  'Медосмотр:',
                  _w.medicalCheckAt?.toIso8601String() ?? '-',
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PrimaryButton(
                label: 'Сохранить в файлы',
                leading: SvgPicture.asset(
                  'assets/svg/ic-download.svg',
                  width: 19,
                  height: 19,
                ),
                loading: _saving,
                onPressed: _w.hasPdf ? _saveToFiles : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- typography helpers ---

  Widget _title(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textBlack,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    final v = (value == null || value.isEmpty) ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: AppColors.textGrey2,
            fontSize: 14,
            height: 1.35,
          ),
          children: [
            TextSpan(text: label),
            const TextSpan(text: ' '),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  Widget _inline(String label, String value) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: AppColors.textGrey2,
          fontSize: 14,
          height: 1.35,
        ),
        children: [
          TextSpan(text: label),
          const TextSpan(text: ' '),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
