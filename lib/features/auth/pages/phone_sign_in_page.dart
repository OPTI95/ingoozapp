import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';

class PhoneSignInPage extends StatefulWidget {
  const PhoneSignInPage({
    super.key,
    this.isRegisterMode = false,
    this.isResetMode = false,
  });

  final bool isRegisterMode;
  final bool isResetMode;

  @override
  State<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage>
    with SingleTickerProviderStateMixin {
  // Flash call tab
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  // Password tab
  final _pwdPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final AuthRepository _authRepo =
      SupabaseAuthRepository(Supabase.instance.client);

  bool _loading = false;
  bool _codeSent = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  String? _normalizedPhone;
  late final bool _isRegisterMode;
  late final bool _isResetMode;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.isRegisterMode;
    _isResetMode = widget.isResetMode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _pwdPhoneController.dispose();
    _passwordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 20);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  // ─── Flash call flow ───

  Future<void> _sendCode() async {
    final digits = _digitsOnly(_phoneController.text);
    if (digits.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 10 цифр номера (без +7)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      _normalizedPhone = '7$digits';
      await _authRepo.sendPhoneOtp(
        phone: _normalizedPhone!,
        mode: _isResetMode
            ? 'reset'
            : (_isRegisterMode ? 'register' : 'login'),
      );
      if (!mounted) return;

      setState(() => _codeSent = true);
      _startCooldown();
      _codeFocus.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Сейчас вам поступит звонок. Введите последние 4 цифры номера.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 4 последние цифры номера'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_normalizedPhone == null) return;

    setState(() => _loading = true);
    try {
      final result = await _authRepo.verifyPhoneOtp(
        phone: _normalizedPhone!,
        code: code,
        mode: _isResetMode
            ? 'reset'
            : (_isRegisterMode ? 'register' : 'login'),
      );
      if (!mounted) return;
      if (_isResetMode) {
        Navigator.of(context).pushReplacementNamed('/set-password-reset');
      } else if (result.isNew) {
        Navigator.of(context).pushReplacementNamed('/set-password');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Password flow ───

  Future<void> _signInWithPassword() async {
    final digits = _digitsOnly(_pwdPhoneController.text);
    if (digits.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 10 цифр номера (без +7)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите пароль'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authRepo.signInWithPhonePassword(
        phone: '7$digits',
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      String msg = 'Не удалось войти.';
      final lower = e.toString().toLowerCase();
      if (lower.contains('invalid login credentials') ||
          lower.contains('invalid_credentials')) {
        msg = 'Неверный номер или пароль.';
      } else if (lower.contains('network') || lower.contains('socket')) {
        msg = 'Нет подключения к интернету.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('уже используется') ||
        raw.contains('already used') ||
        raw.contains('already exists')) {
      return 'Этот номер уже используется. Войдите в аккаунт.';
    }
    if (raw.contains('не найден') || raw.contains('not found')) {
      return 'Аккаунт с таким номером не найден.';
    }
    if (raw.contains('подождите') ||
        raw.contains('rate') ||
        raw.contains('429')) {
      final match = RegExp(r'(\d+)\s*сек').firstMatch(error.toString());
      if (match != null) {
        return 'Подождите ${match.group(1)} сек. перед повторной отправкой.';
      }
      return 'Слишком частые запросы. Подождите немного.';
    }
    if (raw.contains('неверный код')) {
      return error
          .toString()
          .replaceAll('AuthException(message: ', '')
          .replaceAll(')', '');
    }
    if (raw.contains('превышено')) {
      return 'Превышено количество попыток. Запросите новый код.';
    }
    if (raw.contains('не найден') || raw.contains('истёк')) {
      return 'Код истёк. Запросите новый.';
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return 'Нет подключения к интернету.';
    }
    if (error is AuthException) return error.message;
    return 'Произошла ошибка. Попробуйте позже.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isResetMode
              ? 'Сброс пароля по номеру'
              : (_isRegisterMode ? 'Регистрация по номеру' : 'Вход по номеру'),
        ),
      ),
      body: (_isRegisterMode || _isResetMode) ? _buildCallTab() : _buildPasswordTab(),
    );
  }

  Widget _buildCallTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.phone_callback, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _codeSent
                          ? 'Вам поступит входящий звонок.\nВведите последние 4 цифры номера звонящего.'
                          : 'Введите номер телефона.\nМы позвоним и сбросим — введите последние 4 цифры входящего номера.',
                      style: const TextStyle(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                prefixText: '+7 ',
                hintText: '9XX XXX XX XX',
              ),
              enabled: !_codeSent || _cooldown == 0,
            ),
            const SizedBox(height: 16),
            if (!_codeSent) ...[
              ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Позвонить мне'),
              ),
            ],
            if (_codeSent) ...[
              TextFormField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Последние 4 цифры номера',
                  hintText: '• • • •',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _verifyCode,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isResetMode ? 'Продолжить' : 'Войти'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (_cooldown > 0 || _loading) ? null : _sendCode,
                child: _cooldown > 0
                    ? Text('Позвонить повторно ($_cooldown)')
                    : const Text('Позвонить повторно'),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Войти по Email'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Если вы уже устанавливали пароль, войдите по номеру и паролю.',
                      style: TextStyle(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _pwdPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                prefixText: '+7 ',
                hintText: '9XX XXX XX XX',
              ),
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
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _signInWithPassword,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Войти'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/phone-sign-up'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Регистрация по номеру'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Войти по Email'),
            ),
          ],
        ),
      ),
    );
  }
}
