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
              'full_name, phone, owner_inn, owner_postal_code, owner_address, owner_type')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _nameController.text = (response['full_name'] as String?) ?? '';
        _phoneController.text = (response['phone'] as String?) ?? '';
        _innController.text = (response['owner_inn'] as String?) ?? '';
        _postalCodeController.text =
            (response['owner_postal_code'] as String?) ?? '';
        _addressController.text = (response['owner_address'] as String?) ?? '';
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _innController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
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
                      decoration: const InputDecoration(labelText: 'Телефон'),
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
