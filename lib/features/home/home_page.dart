import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/error/failure.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../billing/domain/repositories/billing_repository.dart';
import '../profile/domain/repositories/profile_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? _balance;
  int _promoCredits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads balance and promo credits from the new API (best-effort — one
  /// failing endpoint must not blank the whole screen).
  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    double balance = _balance ?? 0;
    int credits = _promoCredits;
    try {
      balance = (await sl<BillingRepository>().getBalance()).amount;
    } on Failure {
      // keep previous/zero
    }
    try {
      credits = (await sl<ProfileRepository>().getProfile()).promoWaybillsLeft;
    } on Failure {
      // keep previous/zero
    }
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _promoCredits = credits;
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    await sl<TokenStorage>().clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _openPaymentMethods() async {
    await Navigator.of(context).pushNamed('/payment-methods');
    if (!mounted) return;
    _load();
  }

  Future<void> _openWaybill() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Проверка времени'),
        content: const Text(
          'Время путевого листа берётся из времени вашего устройства. '
          'Проверьте, что дата и время на телефоне установлены правильно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    await Navigator.of(context).pushNamed('/waybill');
    if (!mounted) return;
    _load();
  }

  String get _balanceText =>
      _loading ? '...' : (_balance?.toStringAsFixed(0) ?? '0');

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F1F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(
                      'Закрыть',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _menuCard(
                  title: 'Профиль',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                _menuCard(
                  title: 'Пополнить счёт',
                  trailing: Text(
                    '$_balanceText ₽',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openPaymentMethods();
                  },
                ),
                _menuCard(
                  title: 'Автомобили',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed('/cars');
                  },
                ),
                _menuCard(
                  title: 'Промокод',
                  subtitle: 'Подарочных: $_promoCredits шт.',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await Navigator.of(context).pushNamed('/promo');
                    if (!mounted) return;
                    _load();
                  },
                ),
                _menuCard(
                  title: 'Памятка',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed('/guide');
                  },
                ),
                _menuCard(
                  title: 'Контакты',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed('/contacts');
                  },
                ),
                _menuCard(
                  title: 'Выйти',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _signOut();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuCard({
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: SafeArea(
        child: Stack(
          children: [
            // Big "issue waybill" button.
            Align(
              alignment: const Alignment(0, 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    onPressed: _openWaybill,
                    child: const Text('ВЫПУСТИТЬ ЭПЛ'),
                  ),
                ),
              ),
            ),

            // Top-left menu button.
            Positioned(
              top: 12,
              left: 16,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openMenu,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.menu, color: Colors.black87),
                  ),
                ),
              ),
            ),

            // Top-center balance pill.
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openPaymentMethods,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _balanceText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            '₽',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.add, color: AppColors.green),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
