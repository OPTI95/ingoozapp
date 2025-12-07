import 'package:flutter/material.dart';

import '../../../data/models/waybill_model.dart';
import 'waybill_pdf_preview_page.dart';

class WaybillViewPage extends StatelessWidget {
  const WaybillViewPage({super.key, required this.waybill});

  final WaybillModel waybill;

  @override
  Widget build(BuildContext context) {
    final zone2 = waybill.zone2 ?? const {};
    final zone4 = waybill.zone4 ?? const {};

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
              const SizedBox(height: 16),
              const Text(
                'Зона 1. Собственник (владелец) ТС',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Тип: ${zone2['owner_type'] ?? ''}'),
              Text('ФИО / наименование: ${zone2['owner_name'] ?? ''}'),
              Text('ИНН: ${zone2['owner_inn'] ?? ''}'),
              Text('Адрес: ${zone2['owner_address'] ?? ''}'),
              Text('Телефон: ${zone2['owner_phone'] ?? ''}'),
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
