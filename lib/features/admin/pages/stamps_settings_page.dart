import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StampsSettingsPage extends StatefulWidget {
  const StampsSettingsPage({super.key});

  @override
  State<StampsSettingsPage> createState() => _StampsSettingsPageState();
}

class _StampsSettingsPageState extends State<StampsSettingsPage> {
  final _techController = TextEditingController();
  final _medController = TextEditingController();
  final _medFooterController = TextEditingController();
  final _okpoController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _noAccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _techController.dispose();
    _medController.dispose();
    _medFooterController.dispose();
    _okpoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        _noAccess = true;
        return;
      }

      // проверяем признак администратора
      final profile = await client
          .from('profiles')
          .select('is_admin')
          .eq('user_id', userId)
          .maybeSingle();
      final isAdmin = profile != null && profile['is_admin'] == true;
      if (!isAdmin) {
        _noAccess = true;
        return;
      }

      final response = await client
          .from('stamps')
          .select('key, value')
          .inFilter('key', ['tech_pre', 'med_pre', 'med_footer', 'license_okpo']);

      for (final row in response as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        switch (map['key'] as String) {
          case 'tech_pre':
            _techController.text = (map['value'] as String?) ?? '';
            break;
          case 'med_pre':
            _medController.text = (map['value'] as String?) ?? '';
            break;
          case 'med_footer':
            _medFooterController.text = (map['value'] as String?) ?? '';
            break;
          case 'license_okpo':
            _okpoController.text = (map['value'] as String?) ?? '';
            break;
        }
      }
    } catch (_) {
      // ignore, покажем пустую форму
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = Supabase.instance.client;
    try {
      final rows = [
        {
          'key': 'tech_pre',
          'value': _techController.text.trim(),
        },
        {
          'key': 'med_pre',
          'value': _medController.text.trim(),
        },
        {
          'key': 'med_footer',
          'value': _medFooterController.text.trim(),
        },
        {
          'key': 'license_okpo',
          'value': _okpoController.text.trim(),
        },
      ];
      await client.from('stamps').upsert(rows, onConflict: 'key');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Печати сохранены')), 
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения печатей: $e')), 
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки печатей')), 
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noAccess
              ? const Center(child: Text('Нет доступа'))
              : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Текст печати предрейсового техконтроля (зона 2/3)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _techController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Текст печати предрейсового медосмотра (зона 4)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _medController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Подпись под печатью медосмотра',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _medFooterController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      helperText: 'Например: ООО "КПЛПЗ "ЕМС", лицензия ...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ОКПО (используется во всех путевых листах)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _okpoController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      helperText: 'До 10 цифр. Доступно только администратору.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ),
    );
  }
}
