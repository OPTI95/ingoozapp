import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _emailLoading = false;
  bool _passwordLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  String? _currentEmail;

  String _friendlyError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('этот email уже используется') ||
        lower.contains('already') && lower.contains('email')) {
      return 'Этот email уже используется другим аккаунтом.';
    }
    if (lower.contains('нет активного запроса')) {
      return 'Нет активного запроса смены email. Отправьте запрос снова.';
    }
    if (lower.contains('ссылка устарела') || lower.contains('expired')) {
      return 'Ссылка подтверждения устарела. Отправьте запрос снова.';
    }
    if (lower.contains('unauthorized') || lower.contains('missing auth token')) {
      return 'Сессия истекла. Войдите заново и повторите.';
    }
    return 'Операция не выполнена. Попробуйте ещё раз.';
  }

  @override
  void initState() {
    super.initState();
    _currentEmail = Supabase.instance.client.auth.currentUser?.email;
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    
    setState(() => _emailLoading = true);
    
    try {
      final client = Supabase.instance.client;
      final currentEmail = _currentEmail;
      if (currentEmail == null || currentEmail.isEmpty) {
        throw Exception('Текущий email не найден');
      }
      final newEmail = _newEmailController.text.trim().toLowerCase();
      
      // Проверяем, не занят ли email
      final existingUser = await client
          .rpc('check_email_status', params: {'user_email': newEmail});
      
      if (existingUser.isNotEmpty && existingUser[0]['email_exists'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Этот email уже используется другим пользователем'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _emailLoading = false);
        return;
      }
      
      // Создаём запрос на смену email в Edge Function.
      final requestResp = await client.functions.invoke(
        'email-change',
        body: {
          'action': 'request',
          'new_email': newEmail,
        },
      );
      if (requestResp.status < 200 || requestResp.status >= 300) {
        final err = requestResp.data is Map
            ? (requestResp.data['error'] ?? requestResp.data.toString())
            : 'Не удалось создать запрос';
        throw Exception(err);
      }
      final requestId = requestResp.data is Map
          ? requestResp.data['request_id'] as String?
          : null;
      final confirmToken = requestResp.data is Map
          ? requestResp.data['confirm_token'] as String?
          : null;
      if (requestId == null || requestId.isEmpty) {
        throw Exception('Не удалось получить request_id');
      }
      if (confirmToken == null || confirmToken.isEmpty) {
        throw Exception('Не удалось получить confirm_token');
      }

      // Отправляем письмо подтверждения ТОЛЬКО на старую почту.
      await client.auth.signInWithOtp(
        email: currentEmail,
        shouldCreateUser: false,
        emailRedirectTo:
            'ingoozapp://email-change-confirm?request_id=$requestId&confirm_token=$confirmToken',
      );
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Письмо подтверждения отправлено на старую почту: $currentEmail',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      _newEmailController.clear();
      setState(() => _emailLoading = false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _emailLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _emailLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    
    setState(() => _passwordLoading = true);
    
    try {
      final client = Supabase.instance.client;
      final email = _currentEmail;
      if (email == null || email.isEmpty) {
        throw Exception('Текущий email не найден');
      }
      // Проверяем текущий пароль перед изменением.
      await client.auth.signInWithPassword(
        email: email,
        password: _currentPasswordController.text.trim(),
      );
      // Обновляем пароль
      await client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text.trim(),
        ),
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Пароль успешно изменён!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Очищаем поля
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      setState(() => _passwordLoading = false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _passwordLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Безопасность'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Секция смены email
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.email, color: Colors.orange),
                        SizedBox(width: 12),
                        Text(
                          'Сменить email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Текущий email: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              _currentEmail ?? 'Не указан',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Новый email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите новый email';
                        }
                        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                          return 'Неверный формат email';
                        }
                        if (value.trim() == _currentEmail) {
                          return 'Новый email совпадает с текущим';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _emailLoading ? null : _changeEmail,
                        icon: _emailLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_emailLoading ? 'Отправка...' : 'Сменить email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Секция смены пароля
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'Сменить пароль',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Текущий пароль',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscureCurrentPassword =
                                  !_obscureCurrentPassword,
                            );
                          },
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите текущий пароль';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Новый пароль',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscureNewPassword = !_obscureNewPassword);
                          },
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите новый пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен содержать минимум 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Подтвердите новый пароль',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Подтвердите новый пароль';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _passwordLoading ? null : _changePassword,
                        icon: _passwordLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_passwordLoading ? 'Изменение...' : 'Сменить пароль'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
