import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/waybill.dart';

/// In-app PDF viewer for an issued waybill, with print/share in the AppBar
/// and a "Сохранить в файлы" button at the bottom. If the waybill was
/// charged from promo, saving shows the "Подтверждение списания" dialog
/// before sharing.
class WaybillPdfPage extends StatefulWidget {
  const WaybillPdfPage({super.key, required this.waybill});

  final Waybill waybill;

  @override
  State<WaybillPdfPage> createState() => _WaybillPdfPageState();
}

class _WaybillPdfPageState extends State<WaybillPdfPage> {
  late Future<Uint8List> _pdfFuture;

  String get _filename =>
      'waybill-${widget.waybill.number.isNotEmpty ? widget.waybill.number : widget.waybill.id}.pdf';

  bool get _isPromo => widget.waybill.paymentSource == 'promo';

  @override
  void initState() {
    super.initState();
    _pdfFuture = _downloadPdf();
  }

  /// Downloads the server-generated PDF as raw bytes. Uses a vanilla Dio
  /// (no interceptors) so the URL is fetched as-is.
  Future<Uint8List> _downloadPdf() async {
    final url = widget.waybill.pdfUrl;
    if (url == null || url.isEmpty) {
      throw StateError('PDF недоступен');
    }
    final res = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<bool> _confirmPromoDeduction() async {
    final result = await showDialog<bool>(
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
    return result == true;
  }

  Future<void> _save(Uint8List bytes) async {
    if (_isPromo && !await _confirmPromoDeduction()) return;
    if (!mounted) return;
    await Printing.sharePdf(bytes: bytes, filename: _filename);
  }

  Future<void> _print(Uint8List bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _filename,
    );
  }

  Future<void> _share(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: _filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('PDF путевого листа'),
        actions: [
          FutureBuilder<Uint8List>(
            future: _pdfFuture,
            builder: (context, snap) {
              final ready = snap.connectionState == ConnectionState.done &&
                  snap.hasData;
              return Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/svg/ic-printer.svg',
                      width: 22,
                      height: 22,
                    ),
                    tooltip: 'Печать',
                    onPressed: ready ? () => _print(snap.data!) : null,
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/svg/ic-share.svg',
                      width: 22,
                      height: 22,
                    ),
                    tooltip: 'Поделиться',
                    onPressed: ready ? () => _share(snap.data!) : null,
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Не удалось загрузить PDF',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _pdfFuture = _downloadPdf()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }
          final bytes = snap.data!;
          return Column(
            children: [
              Expanded(
                child: PdfPreview(
                  build: (_) async => bytes,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowPrinting: false,
                  allowSharing: false,
                  useActions: false,
                  pdfFileName: _filename,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: PrimaryButton(
                    label: 'Сохранить в файлы',
                    leading: SvgPicture.asset(
                      'assets/svg/ic-download.svg',
                      width: 19,
                      height: 19,
                    ),
                    onPressed: () => _save(bytes),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
