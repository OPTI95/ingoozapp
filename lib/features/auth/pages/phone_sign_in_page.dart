import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/password_eye.dart';
import '../presentation/bloc/auth_bloc.dart';

class PhoneSignInPage extends StatelessWidget {
  const PhoneSignInPage({
    super.key,
    this.isRegisterMode = false,
    this.isResetMode = false,
  });

  final bool isRegisterMode;
  final bool isResetMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: _PhoneSignInView(
        isRegisterMode: isRegisterMode,
        isResetMode: isResetMode,
      ),
    );
  }
}

class _PhoneSignInView extends StatefulWidget {
  const _PhoneSignInView({
    required this.isRegisterMode,
    required this.isResetMode,
  });

  final bool isRegisterMode;
  final bool isResetMode;

  @override
  State<_PhoneSignInView> createState() => _PhoneSignInViewState();
}

class _PhoneSignInViewState extends State<_PhoneSignInView> {
  // Call-code flow
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  // Password flow
  final _pwdPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _codeSent = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  String? _normalizedPhone;

  bool get _isRegisterMode => widget.isRegisterMode;
  bool get _isResetMode => widget.isResetMode;

  /// 4 digits are required by [_verifyCode] — used to disable the
  /// "Подтвердить код" button so it can't be spammed empty.
  bool get _codeValid => _codeController.text.trim().length == 4;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the code field changes so the "Подтвердить код"
    // button enables/disables in lockstep with input.
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
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

  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // ─── Intent → Bloc events ───

  void _sendCode() {
    final digits = _digitsOnly(_phoneController.text);
    if (digits.length != 10) {
      _snack('Введите 10 цифр номера (без +7)');
      return;
    }
    _normalizedPhone = '7$digits';
    context.read<AuthBloc>().add(AuthCodeRequested(_normalizedPhone!));
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      _snack('Введите 4 последние цифры номера');
      return;
    }
    if (_normalizedPhone == null) return;
    context
        .read<AuthBloc>()
        .add(AuthCodeVerified(phone: _normalizedPhone!, code: code));
  }

  void _signInWithPassword() {
    final digits = _digitsOnly(_pwdPhoneController.text);
    if (digits.length != 10) {
      _snack('Введите 10 цифр номера (без +7)');
      return;
    }
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _snack('Введите пароль');
      return;
    }
    context.read<AuthBloc>().add(
          AuthPasswordLoginRequested(phone: '7$digits', password: password),
        );
  }

  // ─── Bloc state → side effects ───

  void _onState(BuildContext context, AuthState state) {
    if (state is AuthCodeSent) {
      setState(() => _codeSent = true);
      _startCooldown();
      _codeFocus.requestFocus();
      _snack(
        'Сейчас вам поступит звонок. Введите последние 4 цифры номера.',
        error: false,
      );
    } else if (state is AuthAuthenticated) {
      if (_isResetMode) {
        Navigator.of(context).pushReplacementNamed('/set-password-reset');
      } else if (state.isNew) {
        Navigator.of(context).pushReplacementNamed('/set-password');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else if (state is AuthError) {
      _snack(state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        leading: const AppBackButton(),
        title: Text(
          _isResetMode
              ? 'Сброс пароля по номеру'
              : (_isRegisterMode ? 'Регистрация по номеру' : 'Вход по номеру'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: _onState,
        builder: (context, state) {
          final loading = state is AuthInProgress;
          return (_isRegisterMode || _isResetMode)
              ? _buildCallTab(loading)
              : _buildPasswordTab(loading);
        },
      ),
    );
  }

  Widget _buildCallTab(bool loading) {
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
                          ? 'Сейчас поступит звонок с незнакомого номера.\nПосмотрите последние 4 цифры этого номера и введите их ниже.\nЕсли звонок не пришёл — нажмите «Позвонить повторно».'
                          : 'Мы позвоним на ваш номер.\nТрубку брать не нужно — просто посмотрите последние 4 цифры входящего номера.',
                      style: const TextStyle(height: 1.3),
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
                      'Внимание: на номера Tele2 звонок может не поступать.\n'
                      'Рекомендуем использовать номер другого оператора.',
                      style: TextStyle(height: 1.3),
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
                onPressed: loading ? null : _sendCode,
                child: loading
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
                onPressed: (loading || !_codeValid) ? null : _verifyCode,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isResetMode ? 'Продолжить' : 'Подтвердить код'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (_cooldown > 0 || loading) ? null : _sendCode,
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

  Widget _buildPasswordTab(bool loading) {
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
                  icon: PasswordEyeIcon(obscured: _obscurePassword),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _signInWithPassword,
              child: loading
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
              icon: SvgPicture.asset(
                'assets/svg/ic-user-plus.svg',
                width: 18,
                height: 18,
              ),
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
