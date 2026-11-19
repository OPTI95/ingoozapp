import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../domain/entities/waybill.dart';
import '../bloc/waybills_bloc.dart';
import 'waybill_detail_page.dart';
import 'waybill_issue_page.dart';
import 'waybill_pdf_page.dart';

class WaybillsPage extends StatelessWidget {
  const WaybillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WaybillsBloc>(
      create: (_) => sl<WaybillsBloc>()..add(const WaybillsLoadRequested()),
      child: const _WaybillsView(),
    );
  }
}

class _WaybillsView extends StatelessWidget {
  const _WaybillsView();

  static String _date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _issue(BuildContext context) async {
    final issued = await Navigator.of(context).push<Waybill?>(
      MaterialPageRoute(builder: (_) => const WaybillIssuePage()),
    );
    if (issued != null && context.mounted) {
      context.read<WaybillsBloc>().add(const WaybillsLoadRequested());
      // Open the freshly issued waybill straight in the PDF viewer.
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WaybillPdfPage(waybill: issued)),
      );
    }
  }

  void _openDetail(BuildContext context, Waybill waybill) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WaybillDetailPage(waybill: waybill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Электронный путевой лист'),
      ),
      body: BlocBuilder<WaybillsBloc, WaybillsState>(
        builder: (context, state) {
          if (state.status == WaybillsStatus.loading &&
              state.waybills.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == WaybillsStatus.failure &&
              state.waybills.isEmpty) {
            return _ErrorView(
              message: state.errorMessage ?? 'Не удалось загрузить список',
              onRetry: () =>
                  context.read<WaybillsBloc>().add(const WaybillsLoadRequested()),
            );
          }
          if (state.waybills.isEmpty) {
            return Center(
              child: FloatingActionButton.extended(
                heroTag: 'issue-empty',
                onPressed: () => _issue(context),
                icon: const Icon(Icons.add),
                label: const Text('Создать путевой лист'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context
                .read<WaybillsBloc>()
                .add(const WaybillsLoadRequested()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.waybills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final w = state.waybills[index];
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text('№ ${w.number}'),
                    subtitle: Text(
                      '${_date(w.validFrom)} – ${_date(w.validTo)}'
                      '${w.vehiclePlate != null ? ' · ${w.vehiclePlate}' : ''}',
                    ),
                    trailing: w.hasPdf
                        ? const Icon(Icons.picture_as_pdf_outlined)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _openDetail(context, w),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<WaybillsBloc, WaybillsState>(
        builder: (context, state) {
          if (state.waybills.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: 'issue',
            onPressed: () => _issue(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
