import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/models/waybill_model.dart';
import '../services/waybill_pdf_generator.dart';

class WaybillPdfPreviewPage extends StatefulWidget {
  const WaybillPdfPreviewPage({super.key, required this.waybill});

  final WaybillModel waybill;

  @override
  State<WaybillPdfPreviewPage> createState() => _WaybillPdfPreviewPageState();
}

class _WaybillPdfPreviewPageState extends State<WaybillPdfPreviewPage> {
  bool _loading = true;
  String? _driverName;
  CarModel? _car;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    try {
      final waybill = widget.waybill;

      // профиль водителя
      final profile = await client
          .from('profiles')
          .select('full_name')
          .eq('user_id', waybill.userId)
          .maybeSingle();
      final driverName = profile != null ? profile['full_name'] as String? : null;

      // данные автомобиля/лицензиата
      final carResponse = await client
          .from('cars')
          .select()
          .eq('id', waybill.carId)
          .maybeSingle();
      CarModel? car;
      if (carResponse != null) {
        car = CarModel.fromMap(carResponse as Map<String, dynamic>);
      }

      if (!mounted) return;
      setState(() {
        _driverName = driverName;
        _car = car;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final waybill = widget.waybill;
    final zone2 = waybill.zone2 ?? const <String, dynamic>{};
    final zone4 = waybill.zone4 ?? const <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF путевого листа'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => buildWaybillPdf(
                waybill: waybill,
                ownerZone: zone2,
                zone4: zone4,
                driverName: _driverName,
                car: _car,
              ),
              canChangePageFormat: false,
              canChangeOrientation: false,
              pdfFileName: 'waybill_${waybill.number}.pdf',
            ),
    );
  }
}
