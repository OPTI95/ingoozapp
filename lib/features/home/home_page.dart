import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../waybill/pages/waybill_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? _balance;
  bool _loading = true;
  int _promoCredits = 0;

  RealtimeChannel? _profilesChannel;

  String? _profileName;
  String? _profilePhone;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _subscribeToBalanceChanges();
  }

  void _subscribeToBalanceChanges() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // Подписка на изменения баланса текущего пользователя.
    _profilesChannel = client.channel('public:profiles')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) {
          // Как только профайл обновился (в том числе из вебхука Тинькофф) — перезагружаем баланс.
          _loadBalance();
        },
      )
      ..subscribe();
  }

  Future<void> _signOut() async {
    final client = Supabase.instance.client;
    await client.auth.signOut();
    await _profilesChannel?.unsubscribe();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  void dispose() {
    _profilesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _openPaymentMethods() async {
    final result = await Navigator.of(context).pushNamed('/payment-methods');
    if (result == true) {
      _loadBalance();
    }
  }

  Future<void> _openWaybillOrProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    try {
      final profile = await client
          .from('profiles')
          .select(
            'full_name, owner_snils, driver_license_number, driver_license_valid_from, driver_license_valid_to',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      final name = profile != null ? profile['full_name'] as String? : null;
      final snils = profile != null ? profile['owner_snils'] as String? : null;
      final licenseNumber = profile != null
          ? profile['driver_license_number'] as String?
          : null;
      final licenseFrom = profile != null
          ? profile['driver_license_valid_from']
          : null;
      final licenseTo = profile != null
          ? profile['driver_license_valid_to']
          : null;
      final incomplete =
          name == null ||
          name.isEmpty ||
          snils == null ||
          snils.isEmpty ||
          licenseNumber == null ||
          licenseNumber.isEmpty ||
          licenseFrom == null ||
          licenseTo == null;

      if (incomplete) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Перед оформлением путевого листа заполните профиль водителя: ФИО, СНИЛС, номер ВУ и даты "С/ПО".',
            ),
          ),
        );
        Navigator.of(context).pushNamed('/profile');
        return;
      }

      // Проверяем, что у пользователя есть хотя бы один автомобиль
      final cars = await client
          .from('cars')
          .select('id')
          .eq('user_id', user.id);
      final hasCar = cars is List && cars.isNotEmpty;

      if (!hasCar) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Перед оформлением путевого листа добавьте автомобиль',
            ),
          ),
        );
        Navigator.of(context).pushNamed('/cars');
        return;
      }

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

      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const WaybillFormPage()));
      if (!mounted) return;
      _loadBalance();
    } catch (_) {
      if (!mounted) return;
      // В случае ошибки запроса просто отправим в профиль, чтобы пользователь мог проверить данные
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось проверить профиль, откройте и проверьте данные',
          ),
        ),
      );
      Navigator.of(context).pushNamed('/profile');
    }
  }

  Future<void> _loadBalance() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() {
          _balance = 0;
          _loading = false;
        });
        return;
      }

      final response = await client
          .from('profiles')
          .select('balance, full_name, phone, is_admin, promo_waybills_left')
          .eq('user_id', user.id)
          .maybeSingle();

      double parsedBalance = 0;
      String? nameValue;
      String? phoneValue;
      int promoValue = 0;

      if (response != null) {
        final rawBalance = response['balance'];
        if (rawBalance is num) {
          parsedBalance = rawBalance.toDouble();
        } else if (rawBalance is String) {
          parsedBalance = double.tryParse(rawBalance) ?? 0;
        }
        nameValue = response['full_name'] as String?;
        phoneValue = response['phone'] as String?;
        final adminValue = response['is_admin'];
        _isAdmin = adminValue is bool && adminValue;
        final promoRaw = response['promo_waybills_left'];
        if (promoRaw is int) {
          promoValue = promoRaw;
        } else if (promoRaw is num) {
          promoValue = promoRaw.toInt();
        }
      }

      setState(() {
        _balance = parsedBalance;
        _loading = false;
        _profileName = nameValue;
        _profilePhone = phoneValue;
        _promoCredits = promoValue;
      });
    } catch (_) {
      setState(() {
        _balance = 0;
        _loading = false;
      });
    }
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Закрыть'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Профиль'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/profile');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Пополнить счёт'),
                    trailing: Text(
                      _loading
                          ? '... ₽'
                          : '${_balance?.toStringAsFixed(0) ?? '0'} ₽',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _openPaymentMethods();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Автомобили'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/cars');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Промокод'),
                    subtitle: Text('Подарочных: $_promoCredits шт.'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await Navigator.of(context).pushNamed('/promo');
                      if (!mounted) return;
                      _loadBalance();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Памятка'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/guide');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Контакты'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/contacts');
                    },
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: const Text('Админ: печати'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/admin-stamps');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: const Text('Админ: путевые листы'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/admin-waybills');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: const Text('Админ: промокоды'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/admin-promo');
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Выйти'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _signOut();
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceText = _loading
        ? '... ₽'
        : '${_balance?.toStringAsFixed(0) ?? '0'} ₽';

    final isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4A6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _loadBalance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      // Center big button
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openWaybillOrProfile,
                              child: const Text('Электронный путевой лист'),
                            ),
                          ),
                        ),
                      ),
                      // Top controls
                      Positioned(
                        top: 16,
                        left: 16,
                        child: isIOS
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.all(10),
                                  onPressed: _openMenu,
                                  child: const Icon(
                                    CupertinoIcons.line_horizontal_3,
                                  ),
                                ),
                              )
                            : Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _openMenu,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(Icons.menu),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  balanceText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                isIOS
                                    ? CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: _openPaymentMethods,
                                        child: const Icon(
                                          CupertinoIcons.add_circled_solid,
                                          color: CupertinoColors.activeGreen,
                                        ),
                                      )
                                    : InkWell(
                                        onTap: _openPaymentMethods,
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.green,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
