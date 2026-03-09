import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ingoozapp/data/repositories/payment_repository.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/models/waybill_model.dart';
import '../services/waybill_pdf_generator.dart';
import 'waybill_pdf_preview_page.dart';

class WaybillViewPage extends StatefulWidget {
  const WaybillViewPage({
    super.key,
    required this.waybill,
    this.requireChargeOnExport = false,
    this.usePromoForCharge = false,
    this.waybillPrice = 20,
  });

  final WaybillModel waybill;
  final bool requireChargeOnExport;
  final bool usePromoForCharge;
  final double waybillPrice;

  @override
  State<WaybillViewPage> createState() => _WaybillViewPageState();
}

class _WaybillViewPageState extends State<WaybillViewPage> {
  String? _driverName;
  CarModel? _car;
  bool _loadingLinkedData = true;
  bool _savingPdf = false;
  bool _charging = false;
  bool _charged = false;

  @override
  void initState() {
    super.initState();
    _charged = widget.waybill.isConsumed;
    _loadLinkedData();
  }

  Future<void> _loadLinkedData() async {
    final client = Supabase.instance.client;
    try {
      final waybill = widget.waybill;

      final profile = await client
          .from('profiles')
          .select('full_name')
          .eq('user_id', waybill.userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));
      final driverName = profile != null
          ? profile['full_name'] as String?
          : null;

      CarModel? car;
      final carResponse = await client
          .from('cars')
          .select()
          .eq('id', waybill.carId)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));
      if (carResponse != null) {
        car = CarModel.fromMap(carResponse as Map<String, dynamic>);
      }

      if (!mounted) return;
      setState(() {
        _driverName = driverName;
        _car = car;
        _loadingLinkedData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLinkedData = false;
      });
    }
  }

  String _ownerTypeLabel(String? value) {
    if (value != null && value.startsWith('other:')) {
      final label = value.substring('other:'.length).trim();
      return label.isEmpty ? 'Иное' : label;
    }
    switch (value) {
      case 'sole':
        return 'Индивидуальный предприниматель';
      case 'legal':
        return 'ООО';
      case 'individual':
        return 'Физическое лицо';
      case 'other':
        return 'Иное';
      default:
        return '';
    }
  }

  String _licenseDisplayName(Map<String, dynamic> zone2) {
    if (_car != null) {
      final base = (_car!.licenseOrgName ?? '').trim();
      final type = (_car!.licenseType ?? '').trim();
      final customType = (_car!.licenseTypeOtherLabel ?? '').trim();
      String prefix;
      switch (type) {
        case 'individual':
          prefix = 'Физическое лицо';
          break;
        case 'sole':
          prefix = 'Индивидуальный предприниматель';
          break;
        case 'ooo':
          prefix = 'ООО';
          break;
        case 'ao':
          prefix = 'АО';
          break;
        case 'other':
          prefix = customType.isNotEmpty ? customType : 'Иное';
          break;
        default:
          prefix = '';
          break;
      }
      if (prefix.isEmpty) return base;
      if (base.isEmpty) return prefix;
      return '$prefix $base';
    }

    final ownerName = (zone2['owner_name'] ?? '') as String;
    return ownerName;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Future<void> _savePdfToFiles() async {
    if (_savingPdf) return;
    setState(() => _savingPdf = true);
    try {
      final confirmed = await _confirmChargeBeforeExport();
      if (!confirmed) return;
      final charged = await _ensureWaybillCharged();
      if (!charged) return;
      final waybill = widget.waybill;
      final bytes = await buildWaybillPdf(
        waybill: waybill,
        ownerZone: waybill.zone2 ?? const <String, dynamic>{},
        zone4: waybill.zone4 ?? const <String, dynamic>{},
        driverName: _driverName,
        car: _car,
      );
      if (!mounted) return;
      final filename = 'waybill_${waybill.number}.pdf';
      if (Platform.isAndroid) {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Сохранить PDF',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes,
        );
        if (savePath == null || !mounted) return;
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF сохранён')));
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить PDF: $e')));
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }

  Future<bool> _ensureWaybillCharged() async {
    if (!widget.requireChargeOnExport ||
        _charged ||
        widget.waybill.isConsumed) {
      return true;
    }
    if (_charging) return false;
    setState(() => _charging = true);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('Not authenticated');
      }

      if (widget.usePromoForCharge) {
        final profile = await client
            .from('profiles')
            .select('promo_waybills_left')
            .eq('user_id', userId)
            .single();
        final credits = (profile['promo_waybills_left'] as num?)?.toInt() ?? 0;
        if (credits <= 0) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет доступных подарочных листов для списания'),
            ),
          );
          return false;
        }

        final updated = await client
            .from('profiles')
            .update({'promo_waybills_left': credits - 1})
            .eq('user_id', userId)
            .gt('promo_waybills_left', 0)
            .select('promo_waybills_left')
            .maybeSingle();

        if (updated == null) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет доступных подарочных листов для списания'),
            ),
          );
          return false;
        }
      } else {
        final profile = await client
            .from('profiles')
            .select('balance')
            .eq('user_id', userId)
            .single();

        final raw = profile['balance'];
        final currentBalance = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '') ?? 0;
        if (currentBalance < widget.waybillPrice) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Недостаточно средств. Нужно ${widget.waybillPrice.toStringAsFixed(0)} ₽',
              ),
            ),
          );
          return false;
        }

        final newBalance = currentBalance - widget.waybillPrice;
        await client
            .from('profiles')
            .update({'balance': newBalance})
            .eq('user_id', userId);

        final paymentRepository = SupabasePaymentRepository(client);
        await paymentRepository.createPayment(
          amount: widget.waybillPrice.toInt(),
          currency: 'RUB',
          status: 'debited',
          provider: 'waybill_balance',
          providerPaymentId: null,
        );
      }

      await client
          .from('waybills')
          .update({'is_consumed': true})
          .eq('id', widget.waybill.id);

      if (!mounted) return false;
      setState(() => _charged = true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось списать оплату: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _charging = false);
    }
  }

  Future<bool> _confirmChargeBeforeExport() async {
    if (!widget.requireChargeOnExport ||
        _charged ||
        widget.waybill.isConsumed) {
      return true;
    }

    final chargeText = widget.usePromoForCharge
        ? 'Будет списан 1 подарочный лист.'
        : 'Будет списано ${widget.waybillPrice.toStringAsFixed(0)} ₽ с баланса.';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение списания'),
        content: Text(
          '$chargeText\n\nСписание произойдёт при открытии/сохранении PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final waybill = widget.waybill;
    final zone2 = waybill.zone2 ?? const <String, dynamic>{};
    final zone4 = waybill.zone4 ?? const <String, dynamic>{};
    final ownerTypeText = _ownerTypeLabel(zone2['owner_type'] as String?);
    final licenseDisplay = _licenseDisplayName(zone2);
    final licenseOkpo = (zone2['license_okpo'] ?? '') as String;
    final licenseOkudRaw = (zone2['license_okud'] ?? '') as String;
    final licenseOkud = licenseOkudRaw.trim().isEmpty
        ? '0345001'
        : licenseOkudRaw.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр путевого листа'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final confirmed = await _confirmChargeBeforeExport();
              if (!confirmed) return;
              final charged = await _ensureWaybillCharged();
              if (!charged || !mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WaybillPdfPreviewPage(waybill: waybill),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '№ ${waybill.number}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Дата: ${waybill.startDate.toLocal().toString().split(' ').first}  Время выезда: ${waybill.startTime}',
              ),
              const SizedBox(height: 4),
              Text(
                'Пробег при выезде: '
                '${waybill.mileage != null ? '${waybill.mileage} км' : '—'}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Зона 1. Собственник (владелец) ТС',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Тип: ${ownerTypeText.isEmpty ? '—' : ownerTypeText}'),
              Text('ФИО / наименование: ${zone2['owner_name'] ?? ''}'),
              Text('Адрес: ${zone2['owner_address'] ?? ''}'),
              const SizedBox(height: 12),
              Text(
                'Водитель Ф.И.О.: ${(_driverName?.isNotEmpty ?? false) ? _driverName : zone2['owner_name'] ?? ''}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Организация (лицензиат)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (_loadingLinkedData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                )
              else ...[
                Text(
                  'Наименование: ${licenseDisplay.isEmpty ? '—' : licenseDisplay}',
                ),
                Text('ОГРН / ОГРНИП: ${_car?.licenseOgrn ?? '—'}'),
                Text('ИНН: ${_car?.licenseInn ?? '—'}'),
                Text('ОКПО: ${licenseOkpo.isEmpty ? '—' : licenseOkpo}'),
                Text('ОКУД: $licenseOkud'),
                Text('Адрес: ${_car?.licenseAddress ?? '—'}'),
                Text('Телефон: ${_car?.licensePhone ?? '—'}'),
                Text('Номер лицензии: ${_car?.licenseNumber ?? '—'}'),
                Text('Лицензия "С": ${_formatDate(_car?.licenseIssuedAt)}'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Зона 4. Время выезда и медосмотра',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Время выезда: ${zone4['departure_hour']?.toString().padLeft(2, '0') ?? '--'}:${zone4['departure_minute']?.toString().padLeft(2, '0') ?? '--'}',
              ),
              const SizedBox(height: 4),
              Text('Медосмотр: ${zone2['med_check_datetime'] ?? ''}'),
              const SizedBox(height: 24),
              const Text(
                'Сделайте скриншот этого экрана или поделитесь PDF, когда он появится в будущем обновлении.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_savingPdf || _charging) ? null : _savePdfToFiles,
              icon: _savingPdf || _charging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt),
              label: Text(
                _charging
                    ? 'Списываем...'
                    : _savingPdf
                    ? 'Сохраняем...'
                    : 'Сохранить в файлы',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
