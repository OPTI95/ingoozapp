import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/promo_code.dart';
import '../../../data/repositories/promo_repository.dart';

class PromoAdminPage extends StatefulWidget {
  const PromoAdminPage({super.key});

  @override
  State<PromoAdminPage> createState() => _PromoAdminPageState();
}

class _PromoAdminPageState extends State<PromoAdminPage> {
  late final PromoRepository _repository;
  bool _loading = true;
  bool _isAdmin = false;
  List<PromoCode> _codes = const [];

  @override
  void initState() {
    super.initState();
    _repository = PromoRepository(Supabase.instance.client);
    _init();
  }

  Future<void> _showEditDialog(PromoCode code) async {
    final codeController = TextEditingController(text: code.code);
    final quotaController = TextEditingController(
      text: code.waybillQuota.toString(),
    );
    final maxRedemptionsController = TextEditingController(
      text: code.maxRedemptions.toString(),
    );
    DateTime? expiresAt = code.expiresAt;
    bool isActive = code.isActive;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: expiresAt ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setModalState(() {
                  expiresAt = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    23,
                    59,
                    59,
                  );
                });
              }
            }

            Future<void> save() async {
              final codeValue = codeController.text.trim();
              final quota = int.tryParse(quotaController.text.trim());
              final maxRed = int.tryParse(maxRedemptionsController.text.trim());
              if (codeValue.isEmpty || quota == null || quota <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите код и количество > 0')),
                );
                return;
              }
              if (maxRed == null || maxRed <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Укажите лимит активаций > 0')),
                );
                return;
              }
              setModalState(() => saving = true);
              try {
                await _repository.updatePromoCode(
                  promoId: code.id,
                  code: codeValue,
                  waybillQuota: quota,
                  maxRedemptions: maxRed,
                  expiresAt: expiresAt,
                  isActive: isActive,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                await _init();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Промокод "${codeValue.toUpperCase()}" обновлён',
                    ),
                  ),
                );
              } catch (e) {
                setModalState(() => saving = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Не удалось сохранить: $e')),
                );
              }
            }

            return AlertDialog(
              title: const Text('Редактировать промокод'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Код'),
                    ),
                    TextField(
                      controller: quotaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Количество путевых листов',
                      ),
                    ),
                    TextField(
                      controller: maxRedemptionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Лимит активаций',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Действителен до'),
                      subtitle: Text(
                        expiresAt != null
                            ? '${expiresAt!.day.toString().padLeft(2, '0')}.${expiresAt!.month.toString().padLeft(2, '0')}.${expiresAt!.year}'
                            : 'Без срока',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (expiresAt != null)
                            IconButton(
                              tooltip: 'Очистить',
                              onPressed: () =>
                                  setModalState(() => expiresAt = null),
                              icon: const Icon(Icons.close),
                            ),
                          IconButton(
                            onPressed: pickDate,
                            icon: const Icon(Icons.date_range),
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Активен'),
                      value: isActive,
                      onChanged: (value) =>
                          setModalState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }
      final profile = await client
          .from('profiles')
          .select('is_admin')
          .eq('user_id', userId)
          .maybeSingle();
      final isAdmin = (profile?['is_admin'] as bool?) ?? false;
      if (!isAdmin) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }
      final codes = await _repository.fetchAdminPromoCodes();
      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _codes = codes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final codeController = TextEditingController();
    final quotaController = TextEditingController(text: '1');
    final maxRedemptionsController = TextEditingController(text: '1');
    DateTime expiresAt = DateTime.now().add(const Duration(days: 7));
    bool creating = false;

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: expiresAt,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) {
        expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        setState(() {});
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> create() async {
              final code = codeController.text.trim();
              final quota = int.tryParse(quotaController.text.trim());
              final maxRedemptions = int.tryParse(
                maxRedemptionsController.text.trim(),
              );
              if (code.isEmpty || quota == null || quota <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите код и количество > 0')),
                );
                return;
              }
              if (maxRedemptions == null || maxRedemptions <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите лимит активаций > 0')),
                );
                return;
              }
              setModalState(() => creating = true);
              try {
                await _repository.createPromoCode(
                  code: code,
                  waybillQuota: quota,
                  expiresAt: expiresAt,
                  maxRedemptions: maxRedemptions,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                await _init();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Промокод "$code" создан')),
                );
              } catch (e) {
                setModalState(() => creating = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Не удалось создать промокод: $e')),
                );
              }
            }

            return AlertDialog(
              title: const Text('Новый промокод'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Код'),
                  ),
                  TextField(
                    controller: quotaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Количество путевых листов',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Сколько пользователей может активировать промокод',
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: maxRedemptionsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Лимит активаций',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Действителен до'),
                    subtitle: Text(
                      '${expiresAt.day.toString().padLeft(2, '0')}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.year}',
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiresAt,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            expiresAt = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              23,
                              59,
                              59,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: creating
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: creating ? null : create,
                  child: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deactivate(PromoCode code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Деактивировать?'),
        content: Text('Промокод ${code.code} станет недоступен.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deactivatePromoCode(code.id);
      await _init();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Промокод ${code.code} отключен')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _delete(PromoCode code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить промокод?'),
        content: Text(
          'Промокод ${code.code} будет удалён безвозвратно вместе с его активациями.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deletePromoCode(code.id);
      await _init();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Промокод ${code.code} удалён')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ: промокоды')),
        body: const Center(child: CircularProgressIndicator()),
        floatingActionButton: null,
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ: промокоды')),
        body: const Center(child: Text('Доступ запрещён')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Админ: промокоды')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        child: _codes.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Пока нет промокодов.')),
                ],
              )
            : ListView.builder(
                itemCount: _codes.length,
                itemBuilder: (context, index) {
                  final code = _codes[index];
                  final status = code.isRedeemable
                      ? 'Доступен'
                      : code.isExpired
                      ? 'Истёк'
                      : 'Неактивен';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text('${code.code} • ${code.waybillQuota} шт.'),
                      subtitle: Text(
                        'Срок до: ${code.expiresAt != null ? _formatDate(code.expiresAt!) : 'без срока'}\n'
                        'Использовано: ${code.redemptionsCount}/${code.maxRedemptions}\n'
                        'Статус: $status',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Редактировать',
                            onPressed: () => _showEditDialog(code),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Удалить',
                            onPressed: () => _delete(code),
                          ),
                          if (code.isActive)
                            IconButton(
                              icon: const Icon(Icons.block),
                              tooltip: 'Отключить',
                              onPressed: () => _deactivate(code),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
