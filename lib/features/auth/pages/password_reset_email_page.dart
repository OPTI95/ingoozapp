import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/repositories/auth_repository.dart';

/// Валидный email вида `user@example.com` — используется всеми экранами
/// восстановления пароля, чтобы кнопка «Отправить» включалась только после
/// полного ввода адреса.
final RegExp kEmailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Шаг 1 восстановления пароля: ввод email, на который придёт одноразовый код.
class PasswordResetEmailPage extends StatefulWidget {
  const PasswordResetEmailPage({super.key});

  @override
  State<PasswordResetEmailPage> createState() => _PasswordResetEmailPageState();
}

class _PasswordResetEmailPageState extends State<PasswordResetEmailPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final valid = kEmailRegExp.hasMatch(_emailController.text.trim());
    if (valid != _valid) setState(() => _valid = valid);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    setState(() => _loading = true);
    try {
      final result = await sl<AuthRepository>().requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _loading = false);
      if (!result.codeSent) {
        // Backend не подтверждает существование аккаунта: кода не будет,
        // поэтому остаёмся на экране и показываем его формулировку.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.detail ??
                  'Если такой email зарегистрирован, на него придёт код.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }
      Navigator.of(context).pushNamed(
        '/password-reset-code',
        arguments: {'email': email, 'reset_id': result.resetId},
      );
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
        title: const Text('Восстановление пароля'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Введите email, который вы указали при регистрации. '
                'Мы отправим на него одноразовый код подтверждения.',
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_valid && !_loading) _submit();
                },
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Отправить',
                loading: _loading,
                onPressed: _valid ? _submit : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
