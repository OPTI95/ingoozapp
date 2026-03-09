import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailLinkExpiredPage extends StatelessWidget {
  const EmailLinkExpiredPage({
    super.key,
    this.reason,
  });

  final String? reason;

  ({String title, String message}) _contentByReason() {
    switch (reason) {
      case 'recovery':
        return (
          title: 'Ссылка сброса пароля устарела',
          message:
              'Эта ссылка истекла или уже была использована.\n\n'
                  'Чтобы сбросить пароль, вернитесь к входу и снова нажмите '
                  '«Забыли пароль».',
        );
      case 'signup':
        return (
          title: 'Ссылка подтверждения почты устарела',
          message:
              'Ссылка для подтверждения регистрации больше не действует.\n\n'
                  'Вернитесь к входу и зарегистрируйтесь заново, чтобы получить '
                  'новое письмо.',
        );
      case 'email_change':
        return (
          title: 'Ссылка смены почты устарела',
          message:
              'Ссылка для изменения email истекла или уже использована.\n\n'
                  'Откройте настройки профиля и запросите смену почты снова.',
        );
      default:
        return (
          title: 'Ссылка устарела',
          message:
              'Ссылка истекла или уже была использована.\n\n'
                  'Вернитесь к входу и повторите действие:\n'
                  '• Забыли пароль — нажмите «Забыли пароль»\n'
                  '• Подтверждение почты — зарегистрируйтесь заново',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _contentByReason();
    final isEmailChangeReason = reason == 'email_change';
    final isSignedIn = Supabase.instance.client.auth.currentUser != null;
    final shouldReturnToSignIn = !isEmailChangeReason;
    final buttonText = shouldReturnToSignIn
        ? 'Вернуться к входу'
        : (isSignedIn ? 'Вернуться в профиль' : 'Вернуться к входу');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    size: 80,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  content.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      if (shouldReturnToSignIn) {
                        if (isSignedIn) {
                          await Supabase.instance.client.auth.signOut(
                            scope: SignOutScope.local,
                          );
                        }
                        nav.pushNamedAndRemoveUntil('/', (route) => false);
                        return;
                      }
                      if (isSignedIn) {
                        nav.pushNamedAndRemoveUntil('/home', (route) => false);
                        nav.pushNamed('/profile');
                        return;
                      }
                      nav.pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      buttonText,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
