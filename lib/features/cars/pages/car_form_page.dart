import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ingoozapp/core/di/injection.dart';
import 'package:ingoozapp/core/utils/input_formatters.dart';
import 'package:ingoozapp/core/utils/platform_pickers.dart';
import 'package:ingoozapp/core/widgets/app_back_button.dart';
import 'package:ingoozapp/core/widgets/platform_save_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../vehicles/domain/entities/owner_type.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../../vehicles/presentation/bloc/vehicle_form_bloc.dart';

class CarFormPage extends StatelessWidget {
  const CarFormPage({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VehicleFormBloc>(
      create: (_) => sl<VehicleFormBloc>(),
      child: _CarFormView(vehicle: vehicle),
    );
  }
}

class _CarFormView extends StatefulWidget {
  const _CarFormView({this.vehicle});

  final Vehicle? vehicle;

  bool get isEditing => vehicle != null;

  @override
  State<_CarFormView> createState() => _CarFormViewState();
}

class _CarFormViewState extends State<_CarFormView> {
  static final Uri _licensorInfoUri = Uri.parse(
    'https://sicmt.ru/fgis-taksi?type=car',
  );
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  // Собственник ТС
  final _ownerNameController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  final _ownerTypeOtherController = TextEditingController();
  // Лицензиат
  final _licenseOgrnController = TextEditingController();
  final _licenseInnController = TextEditingController();
  final _licenseOrgNameController = TextEditingController();
  final _licenseTypeOtherController = TextEditingController();
  final _licenseOrgAddressController = TextEditingController();
  final _licensePhoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  DateTime? _licenseIssuedAt;
  OwnerType? _ownerType;
  String? _licenseType;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _ownerType = vehicle.ownerType;
      _ownerTypeOtherController.text = vehicle.ownerTypeOtherLabel ?? '';
      _nameController.text = vehicle.displayName;
      _plateController.text = vehicle.plateNumber;
      _ownerNameController.text = vehicle.ownerName ?? '';
      _ownerAddressController.text = vehicle.ownerAddress ?? '';
      _licenseOgrnController.text = vehicle.licenseOgrn ?? '';
      _licenseInnController.text = vehicle.licenseInn ?? '';
      _licenseOrgNameController.text = vehicle.licenseOrgName ?? '';
      _licenseType = vehicle.licenseType;
      _licenseTypeOtherController.text = vehicle.licenseTypeOtherLabel ?? '';
      _licenseOrgAddressController.text = vehicle.licenseAddress ?? '';
      _licensePhoneController.text = RussianPhoneInputFormatter.formatPhone(
        (vehicle.licensePhone ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
      );
      _licenseNumberController.text = vehicle.licenseNumber ?? '';
      _licenseIssuedAt = vehicle.licenseIssuedAt;
    }
  }

  Future<void> _pickLicenseDate() async {
    final now = DateTime.now();
    final picked = await showPlatformDatePicker(
      context: context,
      initialDate: _licenseIssuedAt ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _licenseIssuedAt = picked);
    }
  }

  String _licenseDateLabel() {
    if (_licenseIssuedAt == null) {
      return 'Дата выдачи лицензии ("С")';
    }
    final value = _licenseIssuedAt!;
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return 'Лицензия "С": $day.$month.${value.year}';
  }

  String _ownerTypeUiLabel(OwnerType type) {
    switch (type) {
      case OwnerType.individual:
        return 'Физическое лицо';
      case OwnerType.soleProprietor:
        return 'ИП';
      case OwnerType.legalEntity:
        return 'ООО';
      case OwnerType.other:
        return 'Иное';
    }
  }

  String get _ownerNameFieldLabel {
    if (_ownerType == null) {
      return 'ФИО / наименование собственника';
    }
    switch (_ownerType!) {
      case OwnerType.individual:
        return 'ФИО собственника';
      case OwnerType.soleProprietor:
        return 'ФИО ИП';
      case OwnerType.legalEntity:
        return 'Название организации (ООО и т.д.)';
      case OwnerType.other:
        return 'ФИО / наименование собственника';
    }
  }

  Widget _buildLicenseDateBadge() {
    final text = _licenseDateLabel();
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _pickLicenseDate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ),
          child: Center(child: Text(text, style: textStyle)),
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      onPressed: _pickLicenseDate,
      child: Text(text, style: textStyle),
    );
  }

  String get _licenseOrgNameLabel {
    switch (_licenseType) {
      case 'individual':
        return 'ФИО лицензиата';
      case 'sole':
        return 'ФИО ИП (лицензиат)';
      case 'ooo':
      case 'ao':
      case 'other':
        return 'Название лицензиата';
      default:
        return 'Наименование лицензиата';
    }
  }

  String? _validateLicenseOgrn(String? value) {
    if (_licenseType == null) {
      return 'Сначала выберите тип лицензиата';
    }
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Укажите ОГРН / ОГРНИП или «–»';
    if (v == '-' || v == '–' || v == '—') return null;
    final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
    if (_licenseType == 'sole') {
      if (digitsOnly.length != 15) {
        return 'Для ИП ОГРНИП — 15 цифр, или «–» для самозанятых';
      }
      return null;
    }
    if (digitsOnly.length != 13) {
      return 'Для не-ИП ОГРН — 13 цифр, или «–» для самозанятых';
    }
    return null;
  }

  String? _validateLicenseInn(String? value) {
    if (_licenseType == null) {
      return 'Сначала выберите тип лицензиата';
    }
    final digits = (value ?? '').trim();
    if (digits.isEmpty) return 'Укажите ИНН лицензиата';
    final expectedLength =
        (_licenseType == 'sole' || _licenseType == 'individual') ? 12 : 10;
    if (digits.length != expectedLength) {
      return expectedLength == 12
          ? 'Для ИП/физлица ИНН должен содержать 12 цифр'
          : 'Для остальных типов ИНН должен содержать 10 цифр';
    }
    return null;
  }

  Future<void> _openLicensorInfoLink() async {
    var opened = false;
    try {
      opened = await launchUrl(
        _licensorInfoUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!opened) {
      try {
        opened = await launchUrl(
          _licensorInfoUri,
          mode: LaunchMode.platformDefault,
        );
      } catch (_) {}
    }
    if (opened) return;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _ownerNameController.dispose();
    _ownerAddressController.dispose();
    _ownerTypeOtherController.dispose();
    _licenseOgrnController.dispose();
    _licenseInnController.dispose();
    _licenseOrgNameController.dispose();
    _licenseTypeOtherController.dispose();
    _licenseOrgAddressController.dispose();
    _licensePhoneController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ownerType == null) return;
    if (_licenseType == null) return;
    if (_licenseIssuedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите дату выдачи лицензии "С"')),
      );
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Проверка данных'),
        content: const Text(
          'Точно всё верно? Перепроверьте правильность заполненных данных.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final existing = widget.vehicle;
    final vehicle = Vehicle(
      id: existing?.id,
      displayName: _nameController.text.trim(),
      plateNumber: _plateController.text.trim(),
      ownerType: _ownerType!,
      ownerTypeOtherLabel: _ownerType == OwnerType.other
          ? _trimmedOrNull(_ownerTypeOtherController.text)
          : null,
      ownerName: _trimmedOrNull(_ownerNameController.text),
      ownerAddress: _trimmedOrNull(_ownerAddressController.text),
      // Preserved from the existing record (not edited on this form).
      vin: existing?.vin,
      stsNumber: existing?.stsNumber,
      insuranceNumber: existing?.insuranceNumber,
      licenseType: _licenseType,
      licenseTypeOtherLabel: _licenseType == 'other'
          ? _trimmedOrNull(_licenseTypeOtherController.text)
          : null,
      licenseOrgName: _trimmedOrNull(_licenseOrgNameController.text),
      licenseAddress: _trimmedOrNull(_licenseOrgAddressController.text),
      licensePhone: _trimmedOrNull(_licensePhoneController.text),
      licenseNumber: _trimmedOrNull(_licenseNumberController.text),
      licenseOgrn: _trimmedOrNull(_licenseOgrnController.text),
      licenseInn: _trimmedOrNull(_licenseInnController.text),
      licenseIssuedAt: _licenseIssuedAt,
      isActive: existing?.isActive ?? true,
    );

    if (!mounted) return;
    context.read<VehicleFormBloc>().add(VehicleFormSubmitted(vehicle));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          widget.isEditing ? 'Редактировать автомобиль' : 'Добавить автомобиль',
        ),
      ),
      body: BlocConsumer<VehicleFormBloc, VehicleFormState>(
        listener: (context, state) {
          if (state.status == VehicleFormStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.status == VehicleFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Ошибка сохранения'),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Марка и модель авто',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите марку и модель авто';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(labelText: 'Госномер'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Введите госномер'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OwnerType>(
                    value: _ownerType,
                    decoration: const InputDecoration(
                      labelText: 'Тип собственника ТС',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: OwnerType.individual,
                        child: Text(_ownerTypeUiLabel(OwnerType.individual)),
                      ),
                      DropdownMenuItem(
                        value: OwnerType.soleProprietor,
                        child: Text(_ownerTypeUiLabel(OwnerType.soleProprietor)),
                      ),
                      DropdownMenuItem(
                        value: OwnerType.legalEntity,
                        child: Text(_ownerTypeUiLabel(OwnerType.legalEntity)),
                      ),
                      DropdownMenuItem(
                        value: OwnerType.other,
                        child: Text(_ownerTypeUiLabel(OwnerType.other)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _ownerType = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите тип собственника';
                      }
                      return null;
                    },
                  ),
                  if (_ownerType == OwnerType.other) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerTypeOtherController,
                      decoration: const InputDecoration(
                        labelText: 'Свой тип собственника',
                        helperText: 'Например: АО, НКО, МУП и т.д.',
                        helperMaxLines: 2,
                      ),
                      validator: (value) {
                        if (_ownerType != OwnerType.other) return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите тип собственника';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Собственник (владелец) ТС',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: InputDecoration(
                      labelText: _ownerNameFieldLabel,
                      helperText:
                          'Пишите только название/ФИО, тип подставится автоматически.',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите собственника ТС';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ownerAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес собственника',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите адрес собственника';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Лицензиат (организация, на которую оформлена лицензия)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Всю подробную информацию о лицензиате можно получить на сайте '
                          'по номеру автомобиля:',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _openLicensorInfoLink,
                          child: Text(
                            _licensorInfoUri.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseOgrnController,
                    maxLength: 15,
                    decoration: const InputDecoration(
                      labelText: 'ОГРН / ОГРНИП',
                      helperText: '13 цифр (не ИП) или 15 цифр (ИП).',
                      helperMaxLines: 2,
                      counterText: '',
                      errorMaxLines: 2,
                    ),
                    validator: _validateLicenseOgrn,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: const Text(
                      'Если вы самозанятый и являетесь перевозчиком, '
                      'в поле ОГРН можете поставить «–».',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseInnController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'ИНН лицензиата',
                      helperText: '12 цифр (ИП/физлицо) или 10 цифр (остальные).',
                      helperMaxLines: 2,
                      counterText: '',
                      errorMaxLines: 2,
                    ),
                    validator: _validateLicenseInn,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _licenseType,
                    decoration:
                        const InputDecoration(labelText: 'Тип лицензиата'),
                    items: const [
                      DropdownMenuItem(
                        value: 'individual',
                        child: Text('Физическое лицо'),
                      ),
                      DropdownMenuItem(value: 'sole', child: Text('ИП')),
                      DropdownMenuItem(value: 'ooo', child: Text('ООО')),
                      DropdownMenuItem(value: 'ao', child: Text('АО')),
                      DropdownMenuItem(value: 'other', child: Text('Иное')),
                    ],
                    onChanged: (value) => setState(() => _licenseType = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Выберите тип лицензиата';
                      }
                      return null;
                    },
                  ),
                  if (_licenseType == 'other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licenseTypeOtherController,
                      decoration: const InputDecoration(
                        labelText: 'Свой тип лицензиата',
                        helperText: 'Например: НКО, МУП и т.д.',
                      ),
                      validator: (value) {
                        if (_licenseType != 'other') return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Укажите тип лицензиата';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseOrgNameController,
                    decoration: InputDecoration(
                      labelText: _licenseOrgNameLabel,
                      helperText:
                          'Пишите только название/ФИО, тип подставится автоматически.',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите название лицензиата';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseOrgAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес организации',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите адрес организации';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licensePhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(16),
                      const RussianPhoneInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Телефон организации',
                      helperText: 'Формат +7 XXX-XXX-XX-XX',
                      helperMaxLines: 2,
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Укажите телефон организации';
                      }
                      final re = RegExp(r'^\+7 \d{3}-\d{3}-\d{2}-\d{2}$');
                      if (!re.hasMatch(v)) {
                        return 'Введите телефон в формате +7 XXX-XXX-XX-XX';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseNumberController,
                    maxLength: 10,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Номер лицензии на перевозку',
                      helperText:
                          'До 10 символов, цифры и "-", как 432754 или 324942-1.',
                      helperMaxLines: 2,
                      counterText: '',
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'Укажите номер лицензии';
                      }
                      if (!RegExp(r'^[0-9-]{1,10}$').hasMatch(v)) {
                        return 'Разрешены только цифры и "-" (до 10 символов)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLicenseDateBadge(),
                  const SizedBox(height: 8),
                  const Text(
                    'Дата выдачи лицензии',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  PlatformSaveButton(
                    label: 'Сохранить',
                    loading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
