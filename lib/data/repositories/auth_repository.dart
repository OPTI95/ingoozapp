import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_profile.dart';

/// Defines contract for authentication flows.
abstract class AuthRepository {
  Future<UserProfile?> currentUser();
  Future<UserProfile> signInWithEmail({required String email, required String password});
  Future<UserProfile> signUpWithEmail({required String email, required String password});
  Future<UserProfile> signInWithGoogle();
  Future<UserProfile> signInWithWhatsApp({required String phone, required String otp});
  Future<void> sendPasswordResetEmail({required String email});
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
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw AuthException('User not returned');
    }
    return UserProfile(id: user.id, email: user.email ?? email);
  }

  @override
  Future<UserProfile> signInWithGoogle() {
    // Google sign-in is currently disabled.
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'ingooz://reset-password',
    );
  }

  @override
  Future<UserProfile> signInWithWhatsApp({required String phone, required String otp}) {
    // TODO: call custom Supabase Edge Function to verify WhatsApp OTP.
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
