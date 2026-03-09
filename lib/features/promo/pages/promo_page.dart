import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ingoozapp/core/widgets/platform_save_button.dart';
import 'package:ingoozapp/data/models/promo_redemption.dart';
import 'package:ingoozapp/data/repositories/promo_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  final _codeController = TextEditingController();
  late final PromoRepository _repository;

  bool _loading = true;
  bool _redeeming = false;
  bool _profileReady = true;
  String? _profileHint;
  int _promoCredits = 0;
  List<PromoRedemption> _redemptions = const [];

  @override
  void initState() {
    super.initState();
    _repository = PromoRepository(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _profileReady = false;
          _profileHint = 'Требуется вход в аккаунт.';
          _promoCredits = 0;
          _redemptions = const [];
        });
        return;
      }
      final profile = await client
          .from('profiles')
          .select(
            'promo_waybills_left, full_name, owner_snils, driver_license_number, driver_license_valid_from, driver_license_valid_to',
          )
          .eq('user_id', userId)
          .maybeSingle();
      final hasProfile = profile != null;
      final hasRequiredDriverData =
          hasProfile &&
          (profile['full_name'] as String?)?.trim().isNotEmpty == true &&
          (profile['owner_snils'] as String?)?.trim().isNotEmpty == true &&
          (profile['driver_license_number'] as String?)?.trim().isNotEmpty ==
              true &&
          profile['driver_license_valid_from'] != null &&
          profile['driver_license_valid_to'] != null;
      final credits = profile?['promo_waybills_left'];
      final history = await _repository.fetchRedemptions();
      if (!mounted) return;
      setState(() {
        _profileReady = hasRequiredDriverData;
        _profileHint = hasRequiredDriverData
            ? null
            : 'Сначала заполните профиль водителя (ФИО, СНИЛС, ВУ, даты "С/ПО"), потом активируйте промокод.';
        _promoCredits = credits is int
            ? credits
            : credits is num
            ? credits.toInt()
            : 0;
        _redemptions = history;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить промокоды: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _redeem() async {
    if (!_profileReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _profileHint ??
                'Сначала заполните профиль водителя, потом активируйте промокод.',
          ),
        ),
      );
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите промокод')));
      return;
    }
    setState(() => _redeeming = true);
    try {
      final newCredits = await _repository.redeemCode(code);
      if (!mounted) return;
      _codeController.clear();
      setState(() {
        _promoCredits = newCredits;
      });
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Промокод успешно активирован')),
      );
    } on PostgrestException catch (error) {
      final mapped = _mapError(error);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось активировать промокод: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _redeeming = false);
      }
    }
  }

  String _mapError(PostgrestException error) {
    final msg = error.message.toUpperCase();
    if (msg.contains('PROMO_NOT_FOUND')) {
      return 'Промокод не найден';
    }
    if (msg.contains('PROMO_EXPIRED')) {
      return 'Срок действия промокода истёк';
    }
    if (msg.contains('PROMO_LIMIT_REACHED')) {
      return 'Лимит активаций промокода исчерпан';
    }
    if (msg.contains('PROMO_ALREADY_USED')) {
      return 'Вы уже активировали этот промокод';
    }
    if (msg.contains('PROMO_REDEMPTIONS_USER_ID_FKEY') ||
        msg.contains('VIOLATES FOREIGN KEY CONSTRAINT')) {
      return 'Сначала заполните профиль, затем повторите активацию промокода.';
    }
    return 'Ошибка при активации: ${error.message}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCreditsCard(),
                const SizedBox(height: 16),
                if (!_profileReady)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _profileHint ??
                          'Сначала заполните профиль, затем активируйте промокод.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                _buildInputCard(),
                const SizedBox(height: 16),
                _buildHistoryCard(),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Промокоды')),
      body: body,
    );
  }

  Widget _buildCreditsCard() {
    return Card(
      elevation: Platform.isIOS ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подарочные путевые листы',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$_promoCredits шт.',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Они списываются автоматически перед списанием денег с баланса.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Активировать промокод',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Введите код'),
            ),
            const SizedBox(height: 16),
            PlatformSaveButton(
              label: 'Активировать',
              loading: _redeeming,
              onPressed: _profileReady ? _redeem : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История активаций',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_redemptions.isEmpty)
              const Text(
                'Вы ещё не активировали промокоды.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ..._redemptions.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.code),
                  subtitle: Text(
                    'Подарено: ${item.waybillQuota} лист.\n${_formatDate(item.redeemedAt)}',
                  ),
                  leading: const Icon(Icons.card_giftcard),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
