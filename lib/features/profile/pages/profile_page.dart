import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _innController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _snilsController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();

  DateTime? _driverLicenseValidFrom;
  DateTime? _driverLicenseValidTo;

  OwnerType _ownerType = OwnerType.individual;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      final response = await client
          .from('profiles')
          .select(
              'full_name, phone, owner_inn, owner_postal_code, owner_address, owner_type, owner_snils, driver_license_number, driver_license_valid_from, driver_license_valid_to')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _nameController.text = (response['full_name'] as String?) ?? '';
        _phoneController.text = (response['phone'] as String?) ?? '';
        _innController.text = (response['owner_inn'] as String?) ?? '';
        _postalCodeController.text =
            (response['owner_postal_code'] as String?) ?? '';
        _addressController.text = (response['owner_address'] as String?) ?? '';
        _snilsController.text = (response['owner_snils'] as String?) ?? '';
        _driverLicenseNumberController.text =
            (response['driver_license_number'] as String?) ?? '';
        _driverLicenseValidFrom = _parseDateValue(response['driver_license_valid_from']);
        _driverLicenseValidTo = _parseDateValue(response['driver_license_valid_to']);
        _ownerType = OwnerTypeX.fromValue(response['owner_type'] as String?);
      }
    } catch (_) {
      // ignore, покажем пустую форму
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  DateTime? _parseDateValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'Не выбрано';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _innController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _snilsController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не найден')), 
      );
      return;
    }

    try {
      final existing = await client
          .from('profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      final data = {
        'user_id': userId,
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'owner_inn': _innController.text.trim(),
        'owner_postal_code': _postalCodeController.text.trim(),
        'owner_address': _addressController.text.trim(),
        'owner_snils': _snilsController.text.trim(),
        'driver_license_number': _driverLicenseNumberController.text.trim(),
        'driver_license_valid_from':
            _driverLicenseValidFrom?.toIso8601String(),
        'driver_license_valid_to': _driverLicenseValidTo?.toIso8601String(),
        'owner_type': _ownerType.value,
      };

      if (existing == null) {
        await client.from('profiles').insert(data);
      } else {
        await client
            .from('profiles')
            .update(data)
            .eq('user_id', userId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')), 
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении профиля: $e')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')), 
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<OwnerType>(
                      value: _ownerType,
                      decoration: const InputDecoration(
                        labelText: 'Тип лица (владелец)',
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
                      controller: _driverLicenseNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Водительское удостоверение (серия + номер)',
                        helperText: 'Например 7735803290',
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickLicenseDate(isFrom: true),
                            child: Text('Действительно с: ${_formatDisplayDate(_driverLicenseValidFrom)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickLicenseDate(isFrom: false),
                            child: Text('Действительно по: ${_formatDisplayDate(_driverLicenseValidTo)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'ФИО / наименование'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите ФИО или наименование';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _innController,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'ИНН',
                        helperText:
                            '12 цифр (физ. лицо) или 10 цифр (юр. лицо). Найти можно на сайте налоговой.',
                        helperMaxLines: 2,
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return null; // ИНН можно оставить пустым
                        if (v.length != 10 && v.length != 12) {
                          return 'ИНН должен содержать 10 или 12 цифр';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Индекс',
                        helperText:
                            'Индекс можно найти по адресу на почтовых сервисах (Почта России и т.п.).',
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Полный адрес'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Телефон'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _snilsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'СНИЛС',
                        helperText: 'Формат XXX-XXX-XXX-XX. Можно найти в СНИЛС.',
                        helperMaxLines: 2,
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return null;
                        final snilsRegex = RegExp(r'^\d{3}-\d{3}-\d{3}-\d{2} ?$');
                        if (!snilsRegex.hasMatch(v)) {
                          return 'Введите СНИЛС в формате XXX-XXX-XXX-XX';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
