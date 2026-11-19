import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../guide/domain/entities/guide_file.dart';
import '../../guide/presentation/bloc/guide_bloc.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GuideBloc>(
      create: (_) => sl<GuideBloc>()..add(const GuideLoadRequested()),
      child: const _GuideView(),
    );
  }
}

class _GuideView extends StatelessWidget {
  const _GuideView();

  static String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }

  Future<void> _openFile(BuildContext context, GuideFile file) async {
    final url = file.fileUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл недоступен')),
      );
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть «${file.title}»')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Памятка'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Здесь собраны файлы с инструкциями и регламентами. '
              'Администраторы могут добавлять новые PDF, они сразу становятся '
              'доступны.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<GuideBloc, GuideState>(
                builder: (context, state) {
                  if (state.status == GuideStatus.loading &&
                      state.files.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == GuideStatus.failure &&
                      state.files.isEmpty) {
                    return _ErrorView(
                      message:
                          state.errorMessage ?? 'Не удалось загрузить памятку',
                      onRetry: () => context
                          .read<GuideBloc>()
                          .add(const GuideLoadRequested()),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context
                        .read<GuideBloc>()
                        .add(const GuideLoadRequested()),
                    child: state.files.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('Документов пока нет.')),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.files.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final file = state.files[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    file.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: file.createdAt != null
                                      ? Text(
                                          'Загружено: ${_formatDate(file.createdAt)}',
                                        )
                                      : null,
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                  ),
                                  onTap: () => _openFile(context, file),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
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
