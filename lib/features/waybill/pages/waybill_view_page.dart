import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/models/waybill_model.dart';
import 'waybill_pdf_preview_page.dart';

class WaybillViewPage extends StatefulWidget {
  const WaybillViewPage({super.key, required this.waybill});

  final WaybillModel waybill;

  @override
  State<WaybillViewPage> createState() => _WaybillViewPageState();
}

class _WaybillViewPageState extends State<WaybillViewPage> {
  String? _driverName;
  CarModel? _car;
  bool _loadingLinkedData = true;

  @override
  void initState() {
    super.initState();
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
          .maybeSingle();
      final driverName = profile != null ? profile['full_name'] as String? : null;

      CarModel? car;
      final carResponse = await client
          .from('cars')
          .select()
          .eq('id', waybill.carId)
          .maybeSingle();
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
    switch (value) {
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

  String _licenseDisplayName(Map<String, dynamic> zone2) {
    if (_car != null) {
      final base = _car!.licenseOrgName ?? '';
      String prefix;
      switch (_car!.ownerType) {
        case OwnerType.soleProprietor:
          prefix = 'Индивидуальный предприниматель';
          break;
        case OwnerType.legalEntity:
          prefix = 'Юридическое лицо';
          break;
        case OwnerType.individual:
          prefix = '';
          break;
      }
      if (prefix.isEmpty) return base;
      if (base.isEmpty) return prefix;
      return '$prefix $base';
    }

    final ownerName = (zone2['owner_name'] ?? '') as String;
    final ownerType = _ownerTypeLabel(zone2['owner_type'] as String?);
    if (ownerType.isEmpty) return ownerName;
    if (ownerName.isEmpty) return ownerType;
    return '$ownerType $ownerName';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final waybill = widget.waybill;
    final zone2 = waybill.zone2 ?? const <String, dynamic>{};
    final zone4 = waybill.zone4 ?? const <String, dynamic>{};
    final ownerTypeText = _ownerTypeLabel(zone2['owner_type'] as String?);
    final licenseDisplay = _licenseDisplayName(zone2);
    final licenseOkpo = (zone2['license_okpo'] ?? '') as String;
    final licenseOkud = (zone2['license_okud'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр путевого листа'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
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
              Text('№ ${waybill.number}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
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
              Text('ИНН: ${zone2['owner_inn'] ?? ''}'),
              Text('Адрес: ${zone2['owner_address'] ?? ''}'),
              Text('Телефон: ${zone2['owner_phone'] ?? ''}'),
              const SizedBox(height: 12),
              Text('Водитель Ф.И.О.: ${(_driverName?.isNotEmpty ?? false) ? _driverName : zone2['owner_name'] ?? ''}'),
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
                Text('Наименование: ${licenseDisplay.isEmpty ? '—' : licenseDisplay}'),
                Text('ОГРН / ОГРНИП: ${_car?.licenseOgrn ?? '—'}'),
                Text('ИНН: ${_car?.licenseInn ?? '—'}'),
                Text('ОКПО: ${licenseOkpo.isEmpty ? '—' : licenseOkpo}'),
                Text('ОКУД: ${licenseOkud.isEmpty ? '—' : licenseOkud}'),
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
                  'Время выезда: ${zone4['departure_hour']?.toString().padLeft(2, '0') ?? '--'}:${zone4['departure_minute']?.toString().padLeft(2, '0') ?? '--'}'),
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
    );
  }
}
