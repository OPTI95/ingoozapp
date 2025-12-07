import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/repositories/car_repository.dart';

class CarFormPage extends StatefulWidget {
  const CarFormPage({super.key});

  @override
  State<CarFormPage> createState() => _CarFormPageState();
}

class _CarFormPageState extends State<CarFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _vinController = TextEditingController();
  final _stsController = TextEditingController();
  final _insuranceController = TextEditingController();
  // Лицензиат
  final _licenseOgrnController = TextEditingController();
  final _licenseInnController = TextEditingController();
  final _licenseOkpoController = TextEditingController();
  final _licenseOrgNameController = TextEditingController();
  final _licenseOrgAddressController = TextEditingController();
  final _licensePhoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  DateTime? _licenseIssuedAt;
  OwnerType _ownerType = OwnerType.individual;
  bool _saving = false;
  late final CarRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseCarRepository(Supabase.instance.client);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _vinController.dispose();
    _stsController.dispose();
    _insuranceController.dispose();
    _licenseOgrnController.dispose();
    _licenseInnController.dispose();
    _licenseOkpoController.dispose();
    _licenseOrgNameController.dispose();
    _licenseOrgAddressController.dispose();
    _licensePhoneController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.createCar(
        CarModel(
          id: '',
          userId: '',
          displayName: _nameController.text.trim(),
          plateNumber: _plateController.text.trim(),
          ownerType: _ownerType,
          vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
          stsNumber: _stsController.text.trim().isEmpty ? null : _stsController.text.trim(),
          insuranceNumber: _insuranceController.text.trim().isEmpty
              ? null
              : _insuranceController.text.trim(),
          licenseOrgName: _licenseOrgNameController.text.trim().isEmpty
              ? null
              : _licenseOrgNameController.text.trim(),
          licenseAddress: _licenseOrgAddressController.text.trim().isEmpty
              ? null
              : _licenseOrgAddressController.text.trim(),
          licensePhone: _licensePhoneController.text.trim().isEmpty
              ? null
              : _licensePhoneController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim().isEmpty
              ? null
              : _licenseNumberController.text.trim(),
          licenseOgrn: _licenseOgrnController.text.trim().isEmpty
              ? null
              : _licenseOgrnController.text.trim(),
          licenseInn: _licenseInnController.text.trim().isEmpty
              ? null
              : _licenseInnController.text.trim(),
          licenseOkpo: _licenseOkpoController.text.trim().isEmpty
              ? null
              : _licenseOkpoController.text.trim(),
          licenseIssuedAt: _licenseIssuedAt,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить автомобиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название (опционально)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Госномер'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Введите госномер' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OwnerType>(
                value: _ownerType,
                decoration: const InputDecoration(labelText: 'Тип владельца'),
                items: const [
                  DropdownMenuItem(value: OwnerType.individual, child: Text('Физическое лицо')),
                  DropdownMenuItem(value: OwnerType.soleProprietor, child: Text('ИП')),
                  DropdownMenuItem(value: OwnerType.legalEntity, child: Text('Юр. лицо')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _ownerType = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN (опционально)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stsController,
                decoration: const InputDecoration(labelText: 'СТС (опционально)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _insuranceController,
                decoration: const InputDecoration(labelText: 'Страховка (опционально)'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Лицензиат (организация, на которую оформлена лицензия)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseOgrnController,
                keyboardType: TextInputType.number,
                maxLength: 15,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'ОГРН / ОГРНИП',
                  helperText:
                      '13 цифр (юр. лицо) или 15 цифр (ИП). Найти можно в реестре ФНС.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseInnController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'ИНН лицензиата',
                  helperText:
                      '12 цифр (ИП) или 10 цифр (юр. лицо). Найти можно по организации.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseOkpoController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'ОКПО',
                  helperText:
                      'До 10 цифр. Можно найти по ИНН организации.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseOrgNameController,
                decoration: const InputDecoration(
                  labelText: 'Организация (лицензиат)',
                  helperText:
                      'Название юр. лица или ФИО ИП. Для ИП приставка добавится в шаблоне.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseOrgAddressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес организации',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licensePhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон организации',
                  helperText:
                      'Формат +7 (XXX) XXX-XX-XX, можно ввести просто цифрами.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Номер лицензии на перевозку',
                  helperText:
                      'До 10 символов, цифры и "-", как 432754 или 324942-1.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _licenseIssuedAt ?? now,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _licenseIssuedAt = picked);
                  }
                },
                child: Text(
                  _licenseIssuedAt == null
                      ? 'Дата выдачи лицензии ("С")'
                      : 'Лицензия "С": ${_licenseIssuedAt!.day.toString().padLeft(2, '0')}.${_licenseIssuedAt!.month.toString().padLeft(2, '0')}.${_licenseIssuedAt!.year}',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
