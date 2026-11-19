import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/password_eye.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/repositories/auth_repository.dart';

/// Шаг 3 восстановления пароля: ввод нового пароля после подтверждения кода.
class PasswordResetNewPasswordPage extends StatefulWidget {
  const PasswordResetNewPasswordPage({super.key, required this.resetToken});

  /// Одноразовый токен, полученный на шаге подтверждения кода.
  final String resetToken;

  @override
  State<PasswordResetNewPasswordPage> createState() =>
      _PasswordResetNewPasswordPageState();
}

class _PasswordResetNewPasswordPageState
    extends State<PasswordResetNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit {
    final password = _passwordController.text;
    return password.length >= 6 && _confirmController.text == password;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await sl<AuthRepository>().confirmPasswordReset(
        resetToken: widget.resetToken,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль изменён. Войдите с новым паролем.'),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Новый пароль'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Придумайте новый пароль для входа в аккаунт.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    suffixIcon: IconButton(
                      icon: PasswordEyeIcon(obscured: _obscurePassword),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Минимум 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: 'Подтверждение пароля',
                    suffixIcon: IconButton(
                      icon: PasswordEyeIcon(obscured: _obscureConfirm),
                      onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Сохранить',
                  loading: _loading,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
