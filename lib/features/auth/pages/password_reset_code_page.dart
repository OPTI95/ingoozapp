import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/repositories/auth_repository.dart';

/// Длина одноразового кода, который backend присылает на почту.
const int kResetCodeLength = 6;

/// Шаг 2 восстановления пароля: ввод кода, пришедшего на email.
class PasswordResetCodePage extends StatefulWidget {
  const PasswordResetCodePage({
    super.key,
    required this.email,
    required this.resetId,
  });

  /// Показывается пользователю, чтобы он видел, куда ушёл код.
  final String email;

  /// Идентификатор попытки восстановления из шага «request».
  final int resetId;

  @override
  State<PasswordResetCodePage> createState() => _PasswordResetCodePageState();
}

class _PasswordResetCodePageState extends State<PasswordResetCodePage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  int _resendIn = 60;
  Timer? _timer;

  /// Обновляется при повторной отправке кода — backend заводит новую попытку.
  late int _resetId = widget.resetId;

  bool get _complete => _codeController.text.trim().length == kResetCodeLength;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    setState(() => _loading = true);
    try {
      final resetToken = await sl<AuthRepository>().verifyPasswordResetCode(
        resetId: _resetId,
        code: code,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushNamed(
        '/password-reset-new',
        arguments: {'reset_token': resetToken},
      );
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final result =
          await sl<AuthRepository>().requestPasswordReset(widget.email);
      if (!mounted) return;
      setState(() {
        _resending = false;
        if (result.resetId != null) _resetId = result.resetId!;
      });
      _codeController.clear();
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Код отправлен повторно')),
      );
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _resending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Код подтверждения'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Мы отправили код подтверждения на ${widget.email}. '
                'Введите его ниже. Если письма нет во входящих, проверьте папку «Спам».',
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                enabled: !_loading,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLength: kResetCodeLength,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(kResetCodeLength),
                ],
                onSubmitted: (_) {
                  if (_complete && !_loading) _submit();
                },
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: 'Код из письма',
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Подтвердить',
                loading: _loading,
                onPressed: _complete ? _submit : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    (_resendIn == 0 && !_resending && !_loading) ? _resend : null,
                child: Text(
                  _resendIn == 0
                      ? 'Отправить код повторно'
                      : 'Отправить код повторно через $_resendIn с',
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
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
