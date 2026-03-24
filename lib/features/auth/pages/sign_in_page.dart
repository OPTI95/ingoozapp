import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _showResendButton = false;
  final AuthRepository _authRepository =
      SupabaseAuthRepository(Supabase.instance.client);

  String _friendlyAuthError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Неверный email или пароль.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed') ||
        lower.contains('not confirmed')) {
      return 'Почта не подтверждена. Нажмите "Отправить письмо повторно".';
    }
    if (lower.contains('too many requests') || lower.contains('over_email_send_rate_limit')) {
      return 'Слишком много попыток. Подождите немного и попробуйте снова.';
    }
    if (lower.contains('network') || lower.contains('socketexception')) {
      return 'Нет подключения к интернету. Проверьте сеть.';
    }
    return 'Не удалось войти. Попробуйте позже.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _showResendButton = false;
    });
    try {
      await _authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (error) {
      final errorMessage = error.toString();
      
      // Проверяем, не подтверждён ли email
      if (errorMessage.contains('Email not confirmed') || 
          errorMessage.contains('email_not_confirmed') ||
          errorMessage.contains('not confirmed')) {
        setState(() => _showResendButton = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email не подтверждён. Проверьте почту или отправьте письмо повторно.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyAuthError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendConfirmationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'ingoozapp://email-confirm',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Письмо отправлено повторно. Проверьте почту (и папку "Спам").'),
          duration: Duration(seconds: 5),
        ),
      );
      setState(() => _showResendButton = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в аккаунт')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Войти'),
              ),
              const SizedBox(height: 8),
              if (_showResendButton) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email не подтверждён',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _resendConfirmationEmail,
                        icon: const Icon(Icons.email),
                        label: const Text('Отправить письмо повторно'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                child: const Text('Забыли пароль?'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/sign-up'),
                child: const Text('Нет аккаунта? Зарегистрируйтесь'),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
