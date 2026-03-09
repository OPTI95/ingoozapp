import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
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
  Future<Uint8List>? _pdfBytesFuture;

  Future<Uint8List> _generatePdfBytes() {
    final waybill = widget.waybill;
    return buildWaybillPdf(
      waybill: waybill,
      ownerZone: waybill.zone2 ?? const <String, dynamic>{},
      zone4: waybill.zone4 ?? const <String, dynamic>{},
      driverName: _driverName,
      car: _car,
    );
  }

  Future<Uint8List> _buildPdfBytes() {
    return _pdfBytesFuture ??= _generatePdfBytes();
  }

  Future<void> _printPdf() async {
    final waybill = widget.waybill;
    try {
      await Printing.layoutPdf(
        name: 'waybill_${waybill.number}.pdf',
        onLayout: (_) async => _buildPdfBytes(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка печати: $e')));
    }
  }

  Future<void> _sharePdf() async {
    final waybill = widget.waybill;
    try {
      final bytes = await _buildPdfBytes();
      if (!mounted) return;
      final filename = 'waybill_${waybill.number}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    }
  }

  Future<void> _savePdfToFiles() async {
    final waybill = widget.waybill;
    try {
      final bytes = await _buildPdfBytes();
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
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

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
          .maybeSingle()
          .timeout(const Duration(seconds: 12));
      final driverName = profile != null
          ? profile['full_name'] as String?
          : null;

      // данные автомобиля/лицензиата
      final carResponse = await client
          .from('cars')
          .select()
          .eq('id', waybill.carId)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));
      CarModel? car;
      if (carResponse != null) {
        car = CarModel.fromMap(carResponse);
      }

      if (!mounted) return;
      setState(() {
        _driverName = driverName;
        _car = car;
        _pdfBytesFuture = _generatePdfBytes();
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
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF путевого листа'),
        actions: [
          IconButton(
            tooltip: 'Печать',
            onPressed: _loading ? null : _printPdf,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Поделиться',
            onPressed: _loading ? null : _sharePdf,
            icon: Icon(isIos ? Icons.ios_share : Icons.share_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => _buildPdfBytes(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              useActions: false,
              pdfFileName: 'waybill_${waybill.number}.pdf',
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _savePdfToFiles,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Сохранить в файлы'),
                  ),
                ),
              ),
            ),
    );
  }
}
