import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/waybill_model.dart';
import 'waybill_pdf_preview_page.dart';

class WaybillAdminPanelPage extends StatefulWidget {
  const WaybillAdminPanelPage({super.key});

  @override
  State<WaybillAdminPanelPage> createState() => _WaybillAdminPanelPageState();
}

class _WaybillAdminPanelPageState extends State<WaybillAdminPanelPage> {
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _lookupLoading = false;
  bool _statsLoading = true;
  bool _isAdmin = false;
  List<WaybillModel> _nameResults = const [];
  int _registeredUsersCount = 0;
  int _waybillsLastWeekCount = 0;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _openLatestByName() async {
    final query = _nameController.text.trim();
    if (query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите минимум 2 буквы фамилии/имени')), 
      );
      return;
    }

    setState(() => _lookupLoading = true);

    try {
      final client = Supabase.instance.client;
      final rowsByZone2 = await client
          .from('waybills')
          .select()
          .ilike('zone2->>owner_name', '%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      final rowsByProfile = await client
          .from('waybills')
          .select('*, profiles!inner(full_name)')
          .ilike('profiles.full_name', '%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      final mergedRows = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      void addRows(dynamic rows) {
        if (rows is! List) return;
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final id = row['id']?.toString();
          if (id == null || id.isEmpty) continue;
          if (seenIds.add(id)) {
            mergedRows.add(row);
          }
        }
      }

      addRows(rowsByZone2);
      addRows(rowsByProfile);

      if (mergedRows.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Путевые листы для "$query" не найдены')), 
        );
        setState(() {
          _nameResults = const [];
        });
        return;
      }

      final items = mergedRows
          .map(WaybillModel.fromMap)
          .toList();
      if (!mounted) return;
      setState(() {
        _nameResults = items;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при поиске: $e')), 
      );
    } finally {
      if (mounted) {
        setState(() => _lookupLoading = false);
      }
    }
  }

  Future<void> _checkAdmin() async {
    final client = Supabase.instance.client;
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _loading = false;
          _isAdmin = false;
        });
        return;
      }
      final profile = await client
          .from('profiles')
          .select('is_admin')
          .eq('user_id', userId)
          .maybeSingle();
      final isAdmin = (profile?['is_admin'] as bool?) ?? false;
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _loading = false;
      });
      if (isAdmin) {
        _loadStats();
      } else {
        setState(() => _statsLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isAdmin = false;
        _statsLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final client = Supabase.instance.client;
    try {
      final stats = await client.rpc('admin_dashboard_stats');

      if (!mounted) return;
      var usersTotal = 0;
      var waybillsLast7Days = 0;
      if (stats is List && stats.isNotEmpty) {
        final row = stats.first;
        if (row is Map<String, dynamic>) {
          final usersRaw = row['users_total'];
          final waybillsRaw = row['waybills_last_7_days'];
          usersTotal = usersRaw is num ? usersRaw.toInt() : 0;
          waybillsLast7Days = waybillsRaw is num ? waybillsRaw.toInt() : 0;
        }
      }
      setState(() {
        _registeredUsersCount = usersTotal;
        _waybillsLastWeekCount = waybillsLast7Days;
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  Future<void> _openExistingByNumber() async {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер путевого листа')), 
      );
      return;
    }

    setState(() => _lookupLoading = true);

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('waybills')
          .select()
          .eq('number', number)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Путевой лист №$number не найден')), 
        );
        return;
      }

      final waybill = WaybillModel.fromMap(response as Map<String, dynamic>);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaybillPdfPreviewPage(waybill: waybill),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при поиске: $e')), 
      );
    } finally {
      if (mounted) {
        setState(() => _lookupLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ панель ПЛ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ панель ПЛ')),
        body: const Center(
          child: Text('Доступ запрещён'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Админ панель ПЛ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите номер путевого листа, чтобы открыть PDF.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Пользователи',
                    value: _statsLoading
                        ? '...'
                        : _registeredUsersCount.toString(),
                    subtitle: 'Всего регистраций',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Путевые листы',
                    value: _statsLoading
                        ? '...'
                        : _waybillsLastWeekCount.toString(),
                    subtitle: 'За последние 7 дней',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Номер путевого листа',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _lookupLoading ? null : _openExistingByNumber,
                child: _lookupLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Открыть'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Или найдите по фамилии/имени владельца (берётся из Зоны 1).',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Фамилия или имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _lookupLoading ? null : _openLatestByName,
                child: _lookupLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Найти по фамилии'),
              ),
            ),
            const SizedBox(height: 16),
            if (_nameResults.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _nameResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _nameResults[index];
                    final start = item.startDate;
                    final dateLabel = start != null
                        ? '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}'
                        : '—';
                    return Card(
                      child: ListTile(
                        title: Text('№ ${item.number} • $dateLabel'),
                        subtitle: Text(
                          item.zone2 != null
                              ? (item.zone2!['owner_name'] as String? ?? 'Без имени')
                              : 'Без данных о владельце',
                        ),
                        trailing: const Icon(Icons.picture_as_pdf),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WaybillPdfPreviewPage(waybill: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
