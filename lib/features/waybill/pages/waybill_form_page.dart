import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/models/waybill_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/waybill_repository.dart';
import '../../payments/pages/payment_method_page.dart';
import 'waybill_view_page.dart';

class WaybillFormPage extends StatefulWidget {
  const WaybillFormPage({super.key});

  @override
  State<WaybillFormPage> createState() => _WaybillFormPageState();
}

class _WaybillFormPageState extends State<WaybillFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _odometerController = TextEditingController();

  // Zone 1: owner info
  final _ownerNameController = TextEditingController();
  final _ownerInnController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerSnilsController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();

  DateTime? _driverLicenseValidFrom;
  DateTime? _driverLicenseValidTo;

  OwnerType _ownerType = OwnerType.individual;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.fromDateTime(
    DateTime.now().subtract(const Duration(hours: 1)),
  );

  // Предрейсовые проверки (вычисляются относительно времени выезда)
  DateTime? _techCheckDateTime; // техосмотр: T - 5 минут
  DateTime? _medCheckDateTime; // медосмотр: T - 13 минут

  bool _loading = true;
  bool _saving = false;
  bool _profileIncomplete = false;
  double _balance = 0;

  static const double _waybillPrice = 20;

  List<CarModel> _cars = [];
  CarModel? _selectedCar;

  @override
  void initState() {
    super.initState();
    _recalculateChecks();
    _initData();
  }

  Future<void> _initData() async {
    final client = Supabase.instance.client;
    try {
      final userId = client.auth.currentUser?.id;

      // Load basic profile info to prefill zone 1
      if (userId != null) {
        final profile = await client
            .from('profiles')
            .select(
                'full_name, phone, owner_inn, owner_postal_code, owner_address, owner_type, owner_snils, driver_license_number, driver_license_valid_from, driver_license_valid_to, balance')
            .eq('user_id', userId)
            .maybeSingle();

        if (profile != null) {
          final name = profile['full_name'] as String?;
          final phone = profile['phone'] as String?;
          if (name != null && name.isNotEmpty) {
            _ownerNameController.text = name;
          }
          if (phone != null && phone.isNotEmpty) {
            _ownerPhoneController.text = phone;
          }
          _ownerInnController.text = (profile['owner_inn'] as String?) ?? '';
          _ownerAddressController.text =
              (profile['owner_address'] as String?) ?? '';
          _ownerSnilsController.text = (profile['owner_snils'] as String?) ?? '';
          _driverLicenseNumberController.text =
              (profile['driver_license_number'] as String?) ?? '';
          _driverLicenseValidFrom = _parseDateValue(profile['driver_license_valid_from']);
          _driverLicenseValidTo = _parseDateValue(profile['driver_license_valid_to']);
          _ownerType = OwnerTypeX.fromValue(profile['owner_type'] as String?);
          final rawBalance = profile['balance'];
          if (rawBalance is num) {
            _balance = rawBalance.toDouble();
          } else if (rawBalance is String) {
            _balance = double.tryParse(rawBalance) ?? 0;
          }

          _profileIncomplete =
              (name == null || name.isEmpty || phone == null || phone.isEmpty);
        } else {
          _profileIncomplete = true;
        }
      } else {
        _profileIncomplete = true;
      }

      // Load cars for current user
      final carsResponse = await client.from('cars').select();
      final cars = (carsResponse as List<dynamic>)
          .map((e) => CarModel.fromMap(e as Map<String, dynamic>))
          .toList();

      // Generate next waybill number for this user
      String nextNumber = '00001';
      if (userId != null) {
        final last = await client
            .from('waybills')
            .select('number')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (last != null && last['number'] is String) {
          final lastStr = last['number'] as String;
          final lastInt = int.tryParse(lastStr) ?? 0;
          nextNumber = (lastInt + 1).toString().padLeft(5, '0');
        }
      }

      setState(() {
        _cars = cars;
        _selectedCar = cars.isNotEmpty ? cars.first : null;
        _numberController.text = nextNumber;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _odometerController.dispose();
    _ownerNameController.dispose();
    _ownerInnController.dispose();
    _ownerAddressController.dispose();
    _ownerPhoneController.dispose();
    _ownerSnilsController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  DateTime? _parseDateValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _pickLicenseDate({required bool isFrom}) async {
    final initial = (isFrom ? _driverLicenseValidFrom : _driverLicenseValidTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _driverLicenseValidFrom = picked;
      } else {
        _driverLicenseValidTo = picked;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _recalculateChecks();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _recalculateChecks();
      });
    }
  }

  void _recalculateChecks() {
    final base = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    _techCheckDateTime = base.subtract(const Duration(minutes: 5));
    _medCheckDateTime = base.subtract(const Duration(minutes: 13));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала добавьте автомобиль')), 
      );
      return;
    }

    if (_balance < _waybillPrice) {
      _showInsufficientBalanceDialog();
      return;
    }

    setState(() => _saving = true);

    try {
      await _deductBalance();
      var balanceRefundNeeded = true;
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('Not authenticated');
      }

      final startDate = DateTime(_date.year, _date.month, _date.day);
      final startDateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

      // Simple rule: waybill duration 12 hours
      final endDateTime = startDateTime.add(const Duration(hours: 12));
      final endDate = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);

      final mileage = int.tryParse(_odometerController.text.replaceAll(' ', ''));

      // Load current stamps (admin-configured texts)
      final stampsResponse = await client
          .from('stamps')
          .select('key, value')
          .inFilter('key', ['tech_pre', 'med_pre', 'med_footer', 'license_okpo']);
      final Map<String, String> stamps = {};
      for (final row in stampsResponse as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        stamps[map['key'] as String] = (map['value'] as String?) ?? '';
      }
      final globalOkpo = stamps['license_okpo'] ?? '';
      final medFooter = stamps['med_footer'];

      // Zone 1 (owner) data stored in zone2 JSON вместе с печатью техосмотра
      final zone2 = <String, dynamic>{
        'owner_type': _ownerType.value,
        'owner_name': _ownerNameController.text.trim(),
        'owner_inn': _ownerInnController.text.trim(),
        'owner_snils': _ownerSnilsController.text.trim(),
        'driver_license_number': _driverLicenseNumberController.text.trim(),
        'driver_license_valid_from':
            _driverLicenseValidFrom?.toIso8601String(),
        'driver_license_valid_to': _driverLicenseValidTo?.toIso8601String(),
        'license_okud': _selectedCar?.licenseOkud ?? '',
        'license_okpo': globalOkpo,
        'owner_address': _ownerAddressController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
        'tech_check_datetime': _techCheckDateTime?.toIso8601String(),
        'med_check_datetime': _medCheckDateTime?.toIso8601String(),
        'tech_stamp_text': stamps['tech_pre'],
      };

      // Zone 4: время выезда и медосмотра + печать медосмотра
      final zone4 = <String, dynamic>{
        'departure_hour': _time.hour,
        'departure_minute': _time.minute,
        'med_check_date': _medCheckDateTime?.toIso8601String(),
        'med_check_hour': _medCheckDateTime?.hour,
        'med_check_minute': _medCheckDateTime?.minute,
        'med_stamp_text': stamps['med_pre'],
        'med_stamp_footer': medFooter,
      };

      final waybill = WaybillModel(
        id: 'temp',
        userId: userId,
        carId: _selectedCar!.id,
        number: _numberController.text.trim(),
        startDate: startDate,
        endDate: endDate,
        startTime: _time.format(context),
        mileage: mileage,
        zone2: zone2,
        zone3: null,
        zone4: zone4,
      );

      final repo = SupabaseWaybillRepository(client);
      final created = await repo.createWaybill(waybill);
      balanceRefundNeeded = false;

      // помечаем как использованный сразу после создания,
      // чтобы он больше не появлялся в списке
      await client
          .from('waybills')
          .update({'is_consumed': true})
          .eq('id', created.id);

      if (!mounted) return;
      // открываем экран просмотра, с которого пользователь может сделать скрин/поделиться
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaybillViewPage(waybill: created),
        ),
      );
    } catch (e) {
      await _maybeRefundBalance();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении путевого листа: $e')), 
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deductBalance() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Not authenticated');
    }
    final newBalance = _balance - _waybillPrice;
    await client
        .from('profiles')
        .update({'balance': newBalance})
        .eq('user_id', userId);

    final paymentRepository = SupabasePaymentRepository(client);
    await paymentRepository.createPayment(
      amount: _waybillPrice.toInt(),
      currency: 'RUB',
      status: 'debited',
      provider: 'waybill_balance',
      providerPaymentId: null,
    );

    if (!mounted) return;
    setState(() {
      _balance = newBalance;
    });
  }

  Future<void> _maybeRefundBalance() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    final newBalance = _balance + _waybillPrice;
    await client
        .from('profiles')
        .update({'balance': newBalance})
        .eq('user_id', userId);
    if (!mounted) return;
    setState(() {
      _balance = newBalance;
    });
  }

  void _showInsufficientBalanceDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Недостаточно средств'),
        content: Text(
            'Для оформления путевого листа требуется $_waybillPrice ₽. Пополните баланс, чтобы продолжить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openTopUpPage();
            },
            child: const Text('Пополнить'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTopUpPage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaymentMethodPage()),
    );
    if (result == true) {
      _initData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый путевой лист')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_profileIncomplete)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Внимание: перед оформлением путевого листа заполните ФИО и телефон в разделе "Профиль". Эти данные используются в Зоне 1.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    const Text(
                      'Все данные подтягиваются автоматически из профиля и выбранного авто. Введите только пробег при выезде.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Стоимость: $_waybillPrice ₽',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Баланс: ${_balance.toStringAsFixed(2)} ₽',
                                style: TextStyle(
                                  color: _balance >= _waybillPrice
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _openTopUpPage,
                          child: const Text('Пополнить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<CarModel>(
                      value: _selectedCar,
                      decoration: const InputDecoration(
                        labelText: 'Автомобиль',
                        border: OutlineInputBorder(),
                      ),
                      items: _cars
                          .map(
                            (c) => DropdownMenuItem<CarModel>(
                              value: c,
                              child: Text(
                                c.displayName.isNotEmpty
                                    ? '${c.displayName} (${c.plateNumber})'
                                    : c.plateNumber.isNotEmpty
                                        ? c.plateNumber
                                        : 'Авто',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCar = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Пробег (одометр при выезде), км',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите пробег';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Оплатить $_waybillPrice ₽ и создать'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
