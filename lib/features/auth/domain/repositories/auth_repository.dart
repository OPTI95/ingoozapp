import '../entities/auth_result.dart';
import '../entities/auth_user.dart';
import '../entities/password_reset_request.dart';

/// Contract for the auth feature. Implementations throw a [Failure]
/// (from `core/error`) on any error; callers (blocs) catch it.
abstract class AuthRepository {
  /// Step 1: ask the backend to place a verification call to [phone].
  Future<void> requestCode({required String phone});

  /// Step 2: verify [code]; creates the account on first login.
  /// Persists the returned JWT session as a side effect.
  Future<AuthResult> verifyCode({
    required String phone,
    required String code,
  });

  /// Password login for users who already set one. Persists the session.
  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  });

  /// Email + password login (`POST /auth/login/email/`). Persists the session.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Email + password registration (`POST /auth/register/email/`).
  /// Persists the session.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  });

  /// Change password. Replaces the stored tokens if the backend returns a new pair.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Change email. Returns the updated user.
  Future<AuthUser> changeEmail(String newEmail);

  /// Forgotten-password flow, step 1: email a one-time code.
  Future<PasswordResetRequest> requestPasswordReset(String email);

  /// Forgotten-password flow, step 2: verify the code. Returns `reset_token`.
  Future<String> verifyPasswordResetCode({
    required int resetId,
    required String code,
  });

  /// Forgotten-password flow, step 3: store the new password.
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  });

  /// Whether a (possibly expired, but refreshable) session is stored locally.
  Future<bool> hasSession();

  /// Clears the stored session.
  Future<void> logout();
}
