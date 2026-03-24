import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AuthRepository _authRepository = SupabaseAuthRepository(
    Supabase.instance.client,
  );

  // Для таймера повторной отправки
  int _resendCooldown = 0;
  bool get _canResend => _resendCooldown == 0;

  String _friendlyAuthError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('over_email_send_rate_limit') ||
        lower.contains('too many requests') ||
        lower.contains('statuscode: 429')) {
      final match = RegExp(
        r'after\s+(\d+)\s+seconds',
        caseSensitive: false,
      ).firstMatch(raw);
      final seconds = match?.group(1);
      if (seconds != null) {
        return 'Слишком частая отправка. Попробуйте через $seconds сек.';
      }
      return 'Слишком частая отправка. Попробуйте чуть позже.';
    }

    return 'Не удалось отправить письмо. Попробуйте снова.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Запуск таймера обратного отсчёта (60 секунд)
  void _startResendCooldown() {
    if (_resendCooldown > 0) {
      return; // Если таймер уже запущен, не запускаем заново
    }

    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();

    try {
      // Проверяем статус email (существует ли и подтвержден ли)
      final result = await Supabase.instance.client.rpc(
        'check_email_status',
        params: {'user_email': email},
      );

      if (result.isNotEmpty) {
        final emailExists = result[0]['email_exists'] as bool;
        final emailConfirmed = result[0]['email_confirmed'] as bool;

        if (emailExists) {
          // Email уже существует
          setState(() => _loading = false);
          if (!mounted) return;

          if (emailConfirmed) {
            // Email подтвержден - показываем сообщение
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Пользователь с такой почтой уже существует. Войдите или восстановите пароль.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Войти',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          } else {
            // Email не подтвержден - отправляем письмо повторно
            try {
              await Supabase.instance.client.auth.resend(
                type: OtpType.signup,
                email: email,
                emailRedirectTo: 'ingoozapp://email-confirm',
              );
              if (!mounted) return;

              // Запускаем таймер
              _startResendCooldown();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.mark_email_read, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Письмо отправлено повторно на $email. '
                          'Если не пришло — проверьте папку "Спам".',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 7),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_friendlyAuthError(e)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          return;
        }
      }

      // Email свободен, регистрируем
      await _authRepository.signUpWithEmail(
        email: email,
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;

      // Запускаем таймер и показываем сообщение
      _startResendCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Письмо отправлено на $email. '
                  'Если не пришло — проверьте папку "Спам".',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 7),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const emailDeviceNotice =
        'Уважаемый пользователь!\n'
        'Для подтверждения регистрации убедитесь, что вы вошли в почту на этом устройстве.';
    const yandexDeliveryNotice =
        'В данный момент наблюдаются сбои в получении сообщений на почтовые адреса, зарегистрированные в Яндексе.\n'
        'Используйте для регистрации gmail.com, mail.ru или другие почтовые сервисы.';

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.black87),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        emailDeviceNotice,
                        style: TextStyle(height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.black87),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        yandexDeliveryNotice,
                        style: TextStyle(height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Повторите пароль',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_loading || !_canResend) ? null : _signUp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : _canResend
                    ? const Text('Создать аккаунт')
                    : Text('Подождите ($_resendCooldown)'),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
