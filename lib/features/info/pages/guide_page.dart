import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';

import '../../../data/models/guide_file.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  bool _loading = true;
  bool _uploading = false;
  bool _isAdmin = false;
  List<GuideFile> _files = [];
  final TextEditingController _uploadTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _uploadTitleController.dispose();
    super.dispose();
  }

  Future<void> _deleteFile(GuideFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text('Точно удалить «${file.fileName}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('guide_files')
          .delete()
          .eq('id', file.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл «${file.fileName}» удалён.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить файл: $e')),
      );
    }
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    try {
      final user = client.auth.currentUser;
      bool isAdmin = false;
      if (user != null) {
        final profile = await client
            .from('profiles')
            .select('is_admin')
            .eq('user_id', user.id)
            .maybeSingle();
        isAdmin = (profile?['is_admin'] as bool?) ?? false;
      }

      final rows = await client
          .from('guide_files')
          .select()
          .order('created_at', ascending: false);

      final files = (rows as List<dynamic>)
          .map((e) => GuideFile.fromMap(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _files = files;
        _isAdmin = isAdmin;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить памятку: $e')),
      );
    }
  }

  Future<PlatformFile?> _selectPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  Future<bool> _uploadGuideFile({
    required String displayName,
    required PlatformFile file,
  }) async {
    final normalizedName = displayName.trim().toLowerCase().endsWith('.pdf')
        ? displayName.trim()
        : '${displayName.trim()}.pdf';
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступа. Перезайдите в приложение.')),
      );
      return false;
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось прочитать файл. Попробуйте другой.')),
      );
      return false;
    }

    setState(() => _uploading = true);

    try {
      await client.from('guide_files').insert({
            'file_name': normalizedName,
            'file_base64': base64Encode(bytes),
            'uploaded_by': userId,
          });

      await _load();
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл «$normalizedName» загружен.')),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки файла: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _showUploadSheet() async {
    final titleController = _uploadTitleController;
    titleController.clear();
    PlatformFile? pickedFile;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final canSubmit = titleController.text.trim().isNotEmpty && pickedFile != null && !submitting;

            Future<void> pickFile() async {
              final file = await _selectPdfFile();
              if (file == null) return;
              setModalState(() => pickedFile = file);
            }

            Future<void> submit() async {
              if (!canSubmit || pickedFile == null) return;
              setModalState(() => submitting = true);
              final ok = await _uploadGuideFile(
                displayName: titleController.text.trim(),
                file: pickedFile!,
              );
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.of(ctx).pop();
              } else {
                setModalState(() => submitting = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: bottomInset + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Новый PDF для памятки',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Название файла',
                        hintText: 'Например: Правила эксплуатации',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: submitting ? null : pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(pickedFile?.name ?? 'Выбрать PDF'),
                    ),
                    if (pickedFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Файл: ${pickedFile!.name} (${(pickedFile!.size / 1024).toStringAsFixed(1)} КБ)',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canSubmit ? submit : null,
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(submitting ? 'Загрузка…' : 'Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.clear();
  }

  Future<void> _openFile(GuideFile file) async {
    try {
      final bytes = base64Decode(file.fileBase64);
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл ${file.fileName} повреждён.')),
        );
        return;
      }
      await Printing.sharePdf(bytes: bytes, filename: file.fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть файл: $e')),
      );
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _files.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Документов пока нет.')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          ),
                          title: Text(
                            file.fileName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: file.createdAt != null
                              ? Text('Загружено: ${_formatDate(file.createdAt)}')
                              : null,
                          trailing: _isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'open') {
                                      _openFile(file);
                                    } else if (value == 'delete') {
                                      _deleteFile(file);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'open',
                                      child: Text('Открыть'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Удалить'),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () => _openFile(file),
                        ),
                      );
                    },
                  ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Памятка')),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _uploading ? null : _showUploadSheet,
              icon: const Icon(Icons.upload_file),
              label: const Text('Добавить PDF'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Здесь собраны файлы с инструкциями и регламентами. '
              'Администраторы могут добавлять новые PDF, они сразу становятся '
              'доступны всем пользователям.',
            ),
            const SizedBox(height: 16),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
