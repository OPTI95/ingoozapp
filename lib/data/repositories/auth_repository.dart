import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_profile.dart';

class PhoneVerifyResult {
  final UserProfile user;
  final bool isNew;
  const PhoneVerifyResult({required this.user, required this.isNew});
}

/// Defines contract for authentication flows.
abstract class AuthRepository {
  Future<UserProfile?> currentUser();
  Future<UserProfile> signInWithEmail({required String email, required String password});
  Future<UserProfile> signUpWithEmail({required String email, required String password});
  Future<UserProfile> signInWithGoogle();
  Future<UserProfile> signInWithWhatsApp({required String phone, required String otp});
  Future<UserProfile> signInWithPhonePassword({required String phone, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> sendPhoneOtp({required String phone, String mode = 'login'});
  Future<PhoneVerifyResult> verifyPhoneOtp({
    required String phone,
    required String code,
    String mode = 'login',
  });
  Future<void> setPassword({required String password});
  Future<void> signOut();
}

/// Placeholder Supabase-backed implementation.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> currentUser() async {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;
    return UserProfile(id: user.id, email: user.email ?? '');
  }

  @override
  Future<UserProfile> signInWithEmail({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw AuthException('User not returned');
    }
    return UserProfile(id: user.id, email: user.email ?? email);
  }

  @override
  Future<UserProfile> signUpWithEmail({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'ingoozapp://email-confirm',
    );
    final user = response.user;
    if (user == null) {
      throw AuthException('User not returned');
    }
    return UserProfile(id: user.id, email: user.email ?? email);
  }

  @override
  Future<UserProfile> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'ingoozapp://reset-password',
    );
  }

  @override
  Future<UserProfile> signInWithWhatsApp({required String phone, required String otp}) {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> signInWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    String normalized;
    if (digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))) {
      normalized = '7${digits.substring(1)}';
    } else if (digits.length == 10) {
      normalized = '7$digits';
    } else {
      throw AuthException('Неверный формат номера телефона.');
    }

    final placeholderEmail = 'phone_$normalized@ingooz.local';

    final response = await _client.auth.signInWithPassword(
      email: placeholderEmail,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw AuthException('Не удалось войти.');
    }
    return UserProfile(
      id: user.id,
      email: '',
      phone: user.phone ?? '+$normalized',
    );
  }

  @override
  Future<void> sendPhoneOtp({required String phone, String mode = 'login'}) async {
    final response = await _client.functions.invoke(
      'sms-auth',
      body: {'action': 'send_otp', 'phone': phone, 'mode': mode},
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    if (data['error'] != null) {
      throw AuthException(data['error'] as String);
    }
  }

  @override
  Future<PhoneVerifyResult> verifyPhoneOtp({
    required String phone,
    required String code,
    String mode = 'login',
  }) async {
    final response = await _client.functions.invoke(
      'sms-auth',
      body: {'action': 'verify_otp', 'phone': phone, 'code': code, 'mode': mode},
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    if (data['error'] != null) {
      throw AuthException(data['error'] as String);
    }

    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw AuthException('Не удалось получить сессию.');
    }

    await _client.auth.setSession(refreshToken);

    final isNew = data['is_new'] == true;
    final user = data['user'] as Map<String, dynamic>?;
    return PhoneVerifyResult(
      user: UserProfile(
        id: user?['id'] as String? ?? '',
        email: '',
        phone: user?['phone'] as String? ?? phone,
      ),
      isNew: isNew,
    );
  }

  @override
  Future<void> setPassword({required String password}) async {
    await _client.auth.updateUser(
      UserAttributes(
        password: password,
        data: const {'phone_password_set': true},
      ),
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
