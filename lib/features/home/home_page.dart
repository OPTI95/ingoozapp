import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? _balance;
  bool _loading = true;

  String? _profileName;
  String? _profilePhone;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _signOut() async {
    final client = Supabase.instance.client;
    await client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
          .select('full_name, phone')
          .eq('user_id', user.id)
          .maybeSingle();

      final name = profile != null ? profile['full_name'] as String? : null;
      final phone = profile != null ? profile['phone'] as String? : null;
      final incomplete =
          name == null || name.isEmpty || phone == null || phone.isEmpty;

      if (incomplete) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Перед оформлением путевого листа заполните профиль (ФИО и телефон)',
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

      if (!mounted) return;
      Navigator.of(context).pushNamed('/waybill');
    } catch (_) {
      if (!mounted) return;
      // В случае ошибки запроса просто отправим в профиль, чтобы пользователь мог проверить данные
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось проверить профиль, откройте и проверьте данные'),
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
          .select('balance, full_name, phone, is_admin')
          .eq('user_id', user.id)
          .maybeSingle();

      double parsedBalance = 0;
      String? nameValue;
      String? phoneValue;

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
      }

      setState(() {
        _balance = parsedBalance;
        _loading = false;
        _profileName = nameValue;
        _profilePhone = phoneValue;
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    title: Text(_profileName?.isNotEmpty == true
                        ? _profileName!
                        : 'Профиль'),
                    subtitle: Text(
                      _profilePhone?.isNotEmpty == true
                          ? _profilePhone!
                          : 'Заполните профиль',
                    ),
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
                      final result = await Navigator.of(context)
                          .pushNamed('/payment-methods');
                      if (result == true) {
                        _loadBalance();
                      }
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
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Раздел промокодов пока в разработке')),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Памятка'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Раздел памятки пока в разработке')),
                      );
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
    final balanceText =
        _loading ? '... ₽' : '${_balance?.toStringAsFixed(0) ?? '0'} ₽';

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4A6),
      body: SafeArea(
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
              child: Material(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.of(context)
                              .pushNamed('/payment-methods');
                          if (result == true) {
                            _loadBalance();
                          }
                        },
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
    );
  }
}
