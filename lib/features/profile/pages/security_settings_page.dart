import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/repositories/profile_repository.dart';

/// "Безопасность" — смена email и пароля.
///
/// Note: пока в новом API нет эндпоинтов для смены email и пароля. UI собран
/// по дизайну, а сабмит показывает пользователю короткое сообщение «Функция
/// временно недоступна». Когда бэк добавит эндпоинты
/// (например, `POST /auth/email/change/` и `POST /auth/password/change/`),
/// заменим заглушку `_notImplemented(...)` на реальный вызов через
/// `AuthRepository` / `AuthBloc`.
class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _currentEmail;
  bool _loadingProfile = true;
  bool _submittingEmail = false;
  bool _submittingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentEmail() async {
    try {
      final profile = await sl<ProfileRepository>().getProfile();
      if (!mounted) return;
      setState(() {
        _currentEmail = profile.email;
        _loadingProfile = false;
      });
    } on Failure {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeEmail() async {
    if (_submittingEmail) return;
    if (!_emailFormKey.currentState!.validate()) return;
    final newEmail = _newEmailController.text.trim();
    setState(() => _submittingEmail = true);
    try {
      final user = await sl<AuthRepository>().changeEmail(newEmail);
      if (!mounted) return;
      setState(() {
        _currentEmail = user.email ?? newEmail;
        _newEmailController.clear();
      });
      _showSnack('Email обновлён');
    } on Failure catch (f) {
      if (!mounted) return;
      _showSnack(f.message);
    } finally {
      if (mounted) setState(() => _submittingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    if (_submittingPassword) return;
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _submittingPassword = true);
    try {
      await sl<AuthRepository>().changePassword(
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnack('Пароль обновлён');
    } on Failure catch (f) {
      if (!mounted) return;
      _showSnack(f.message);
    } finally {
      if (mounted) setState(() => _submittingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Безопасность'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Секция смены email.
          Card(
            elevation: 0,
            color: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/ic-mail.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Сменить email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Текущий email: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              _loadingProfile
                                  ? '...'
                                  : ((_currentEmail ?? '').isEmpty
                                      ? 'Не указан'
                                      : _currentEmail!),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Новый email',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(13),
                          child: SvgPicture.asset(
                            'assets/svg/ic-at.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Введите новый email';
                        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) {
                          return 'Неверный формат email';
                        }
                        if (v == _currentEmail) {
                          return 'Новый email совпадает с текущим';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submittingEmail ? null : _changeEmail,
                        icon: _submittingEmail
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/svg/ic-send.svg',
                                width: 18,
                                height: 18,
                              ),
                        label: const Text('Сменить email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Секция смены пароля.
          Card(
            elevation: 0,
            color: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/ic-lock.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            AppColors.brightBlue,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Сменить пароль',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      controller: _currentPasswordController,
                      label: 'Текущий пароль',
                      obscured: _obscureCurrentPassword,
                      onToggle: () => setState(() =>
                          _obscureCurrentPassword = !_obscureCurrentPassword),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Введите текущий пароль'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      controller: _newPasswordController,
                      label: 'Новый пароль',
                      obscured: _obscureNewPassword,
                      onToggle: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите новый пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен содержать минимум 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      controller: _confirmPasswordController,
                      label: 'Подтвердите новый пароль',
                      obscured: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword =
                          !_obscureConfirmPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Подтвердите новый пароль';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submittingPassword ? null : _changePassword,
                        icon: _submittingPassword
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Сменить пароль'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brightBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscured,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscured,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(13),
          child: SvgPicture.asset(
            'assets/svg/ic-lock.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.iconGrey,
              BlendMode.srcIn,
            ),
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: SvgPicture.asset(
            obscured ? 'assets/svg/ic-eye.svg' : 'assets/svg/eye.svg',
            width: 21,
            height: 21,
          ),
        ),
      ),
      validator: validator,
    );
  }
}
