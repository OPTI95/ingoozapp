import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ingoozapp/core/utils/input_formatters.dart';
import 'package:ingoozapp/core/utils/platform_pickers.dart';
import 'package:ingoozapp/core/widgets/platform_save_button.dart';
import 'package:ingoozapp/features/profile/pages/security_settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _snilsController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();

  DateTime? _driverLicenseValidFrom;
  DateTime? _driverLicenseValidTo;
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
            'full_name, owner_snils, driver_license_number, driver_license_valid_from, driver_license_valid_to',
          )
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _nameController.text = (response['full_name'] as String?) ?? '';
        _snilsController.text = SnilsInputFormatter.formatSnils(
          (response['owner_snils'] as String?) ?? '',
        );
        _driverLicenseNumberController.text =
            (response['driver_license_number'] as String?) ?? '';
        _driverLicenseValidFrom = _parseDateValue(
          response['driver_license_valid_from'],
        );
        _driverLicenseValidTo = _parseDateValue(
          response['driver_license_valid_to'],
        );
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final initial =
        (isFrom ? _driverLicenseValidFrom : _driverLicenseValidTo) ??
        DateTime.now();
    final picked = await showPlatformDatePicker(
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

  Widget _buildLicenseBadge({required bool isFrom}) {
    final label = isFrom ? 'С (дата выдачи):' : 'ПО (дата окончания):';
    final value = isFrom ? _driverLicenseValidFrom : _driverLicenseValidTo;
    final textColor = Theme.of(context).colorScheme.primary;
    final labelStyle = TextStyle(
      color: textColor.withOpacity(0.65),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    Widget buildContent(Color borderColor, Color backgroundColor) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            if (Platform.isIOS)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 4),
            Text(_formatDisplayDate(value), style: valueStyle),
          ],
        ),
      );
    }

    if (Platform.isIOS) {
      final border = CupertinoColors.systemGrey3.resolveFrom(context);
      final background = CupertinoColors.systemGrey6.resolveFrom(context);
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _pickLicenseDate(isFrom: isFrom),
        child: buildContent(border, background),
      );
    }

    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final backgroundColor = theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _pickLicenseDate(isFrom: isFrom),
        child: buildContent(borderColor, backgroundColor),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _snilsController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_driverLicenseValidFrom == null || _driverLicenseValidTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите даты ВУ "С" и "ПО"')),
      );
      return;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пользователь не найден')));
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
        'owner_snils': _snilsController.text.trim(),
        'driver_license_number': _driverLicenseNumberController.text.trim(),
        'driver_license_valid_from': _driverLicenseValidFrom?.toIso8601String(),
        'driver_license_valid_to': _driverLicenseValidTo?.toIso8601String(),
      };

      if (existing == null) {
        await client.from('profiles').insert(data);
      } else {
        await client.from('profiles').update(data).eq('user_id', userId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
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
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ListTile(
                        leading: const Icon(
                          Icons.security,
                          color: Colors.orange,
                        ),
                        title: const Text(
                          'Безопасность',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Сменить email или пароль'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SecuritySettingsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const Text(
                      'Данные водителя (обязательно для выпуска путевого листа)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ФИО водителя',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите ФИО водителя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _snilsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        const SnilsInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'СНИЛС водителя',
                        helperText: 'Формат XXX-XXX-XXX-XX',
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Укажите СНИЛС водителя';
                        final snilsRegex = RegExp(r'^\d{3}-\d{3}-\d{3}-\d{2}$');
                        if (!snilsRegex.hasMatch(v)) {
                          return 'Введите СНИЛС в формате XXX-XXX-XXX-XX';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _driverLicenseNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Водительское удостоверение (серия + номер)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите номер водительского удостоверения';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildLicenseBadge(isFrom: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildLicenseBadge(isFrom: false)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PlatformSaveButton(label: 'Сохранить', onPressed: _save),
                  ],
                ),
              ),
            ),
    );
  }
}
