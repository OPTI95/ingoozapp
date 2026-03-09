import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailChangeConfirmPage extends StatefulWidget {
  const EmailChangeConfirmPage({
    required this.requestId,
    required this.confirmToken,
    super.key,
  });

  final String requestId;
  final String confirmToken;

  @override
  State<EmailChangeConfirmPage> createState() => _EmailChangeConfirmPageState();
}

class _EmailChangeConfirmPageState extends State<EmailChangeConfirmPage> {
  bool _loading = true;
  bool _success = false;
  String _message = 'Подтверждаем смену email...';

  @override
  void initState() {
    super.initState();
    _confirmEmailChange();
  }

  Future<void> _confirmEmailChange() async {
    try {
      final hasTokenPair =
          widget.requestId.isNotEmpty && widget.confirmToken.isNotEmpty;
      final response = await Supabase.instance.client.functions.invoke(
        'email-change',
        body: hasTokenPair
            ? {
                'action': 'confirm',
                'request_id': widget.requestId,
                'confirm_token': widget.confirmToken,
              }
            : {
                // Fallback: если deep-link потерял query-параметры,
                // подтверждаем последний активный запрос текущего пользователя.
                'action': 'confirm_latest',
              },
      );

      final isOk = response.status >= 200 && response.status < 300;
      final data = response.data;
      final errorText = data is Map ? data['error']?.toString() : null;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = isOk;
        _message = isOk
            ? 'Email успешно изменён. Теперь входите с новым адресом.'
            : (errorText ?? 'Не удалось подтвердить смену email.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = false;
        _message = 'Ошибка подтверждения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Смена email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                const CircularProgressIndicator()
              else
                Icon(
                  _success ? Icons.check_circle : Icons.error_outline,
                  color: _success ? Colors.green : Colors.red,
                  size: 72,
                ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (!_loading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_success)
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _message = 'Подтверждаем смену email...';
                          });
                          _confirmEmailChange();
                        },
                        child: const Text('Повторить'),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      child: Text(_success ? 'На главную' : 'Открыть приложение'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
