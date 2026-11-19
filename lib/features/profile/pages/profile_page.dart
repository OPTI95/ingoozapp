import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ingoozapp/core/di/injection.dart';
import 'package:ingoozapp/core/theme/app_colors.dart';
import 'package:ingoozapp/core/utils/input_formatters.dart';
import 'package:ingoozapp/core/utils/platform_pickers.dart';
import 'package:ingoozapp/core/widgets/app_back_button.dart';
import 'package:ingoozapp/core/widgets/primary_button.dart';
import 'package:ingoozapp/features/profile/pages/security_settings_page.dart';
import 'package:ingoozapp/features/profile/presentation/bloc/profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _snilsController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();

  DateTime? _driverLicenseValidFrom;
  DateTime? _driverLicenseValidTo;
  bool _populated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _snilsController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  /// Fills the form once, after the initial profile load.
  void _populateFromState(ProfileState state) {
    final profile = state.profile;
    if (_populated || profile == null) return;
    _populated = true;
    _nameController.text = profile.fullName ?? '';
    _snilsController.text =
        SnilsInputFormatter.formatSnils(profile.snils ?? '');
    _driverLicenseNumberController.text = profile.driverLicenseNumber ?? '';
    _driverLicenseValidFrom = profile.driverLicenseValidFrom;
    _driverLicenseValidTo = profile.driverLicenseValidTo;
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_driverLicenseValidFrom == null || _driverLicenseValidTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите даты ВУ "С" и "ПО"')),
      );
      return;
    }
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            fullName: _nameController.text.trim(),
            snils: _snilsController.text.trim(),
            driverLicenseNumber: _driverLicenseNumberController.text.trim(),
            driverLicenseValidFrom: _driverLicenseValidFrom,
            driverLicenseValidTo: _driverLicenseValidTo,
          ),
        );
  }

  void _onState(BuildContext context, ProfileState state) {
    _populateFromState(state);
    if (state.submission == ProfileSubmission.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
    } else if (state.status == ProfileStatus.error ||
        state.submission == ProfileSubmission.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Произошла ошибка')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Профиль'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: _onState,
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    elevation: 0,
                    color: AppColors.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: SvgPicture.asset(
                        'assets/svg/ic-shield.svg',
                        width: 26,
                        height: 26,
                      ),
                      title: const Text(
                        'Безопасность',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text('Сменить email или пароль'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SecuritySettingsPage(),
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
                    decoration: const InputDecoration(labelText: 'ФИО водителя'),
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
                    inputFormatters: [const SnilsInputFormatter()],
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
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Водительское удостоверение (серия + номер)',
                      helperText: 'Например 7735803290',
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
                  PrimaryButton(
                    label: state.isSaving ? 'Сохранение…' : 'Сохранить',
                    loading: state.isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLicenseBadge({required bool isFrom}) {
    final label = isFrom ? 'С (дата выдачи):' : 'ПО (дата окончания):';
    final value = isFrom ? _driverLicenseValidFrom : _driverLicenseValidTo;
    return InkWell(
      onTap: () => _pickLicenseDate(isFrom: isFrom),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 13,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
        ),
        child: Text(
          _formatDisplayDate(value),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
