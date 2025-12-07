import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/models/waybill_model.dart';
import '../../../data/repositories/waybill_repository.dart';
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
                'full_name, phone, owner_inn, owner_postal_code, owner_address, owner_type')
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
          _ownerType = OwnerTypeX.fromValue(profile['owner_type'] as String?);

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
    super.dispose();
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

    setState(() => _saving = true);

    try {
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
          .inFilter('key', ['tech_pre', 'med_pre']);
      final Map<String, String> stamps = {};
      for (final row in stampsResponse as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        stamps[map['key'] as String] = (map['value'] as String?) ?? '';
      }

      // Zone 1 (owner) data stored in zone2 JSON вместе с печатью техосмотра
      final zone2 = <String, dynamic>{
        'owner_type': _ownerType.value,
        'owner_name': _ownerNameController.text.trim(),
        'owner_inn': _ownerInnController.text.trim(),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении путевого листа: $e')), 
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
                      'Зона 1. Собственник (владелец) ТС',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<OwnerType>(
                      value: _ownerType,
                      decoration: const InputDecoration(
                        labelText: 'Тип собственника',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: OwnerType.individual,
                          child: Text('Физическое лицо'),
                        ),
                        DropdownMenuItem(
                          value: OwnerType.soleProprietor,
                          child: Text('ИП'),
                        ),
                        DropdownMenuItem(
                          value: OwnerType.legalEntity,
                          child: Text('Юридическое лицо'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _ownerType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'ФИО / наименование собственника',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите собственника';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerInnController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ИНН собственника',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите ИНН';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Адрес собственника',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Телефон собственника',
                        border: OutlineInputBorder(),
                      ),
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
                      controller: _numberController,
                      decoration: const InputDecoration(
                        labelText: 'Номер путевого листа',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите номер';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text(
                              'Дата выезда: ${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTime,
                            child: Text('Время выезда: ${_time.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Пробег (одометр при выезде), км',
                        border: OutlineInputBorder(),
                      ),
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
                            : const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
