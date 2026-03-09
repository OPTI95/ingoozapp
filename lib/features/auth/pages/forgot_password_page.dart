import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  String _friendlyError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('unexpected_failure') ||
        raw.contains('error sending recovery email') ||
        raw.contains('statuscode: 500')) {
      return 'Сервис отправки писем временно недоступен. Попробуйте позже.';
    }
    if (raw.contains('invalid email')) {
      return 'Некорректный email.';
    }
    return 'Не удалось отправить письмо. Попробуйте позже.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'ingoozapp://reset-password',
      );
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const emailDeviceNotice =
        'Уважаемый пользователь!\n'
        'Для восстановления пароля убедитесь, что вы вошли в почту на этом устройстве.';
    const yandexDeliveryNotice =
        'В данный момент наблюдаются сбои в получении сообщений на почтовые адреса, зарегистрированные в Яндексе.\n'
        'Используйте для регистрации gmail.com, mail.ru или другие почтовые сервисы.';

    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _emailSent
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Письмо отправлено!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Проверьте почту ${_emailController.text.trim()} и перейдите по ссылке для сброса пароля.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Если письма нет во входящих, проверьте папку "Спам".',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Вернуться ко входу'),
                    ),
                  ],
                ),
              )
            : Form(
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
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.black87,
                          ),
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
                    const Text(
                      'Введите email, привязанный к вашему аккаунту. Мы отправим вам письмо со ссылкой для сброса пароля.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите email';
                        }
                        if (!value.contains('@')) {
                          return 'Некорректный email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _sendResetEmail,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Отправить письмо'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
