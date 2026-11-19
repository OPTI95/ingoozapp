import '../../../../core/error/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/password_reset_request.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Coordinates the remote datasource and token storage, translating any
/// data-layer [AppException] into a presentation [Failure] (thrown).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<void> requestCode({required String phone}) async {
    try {
      await _remote.requestCode(phone);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<AuthResult> verifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      final res = await _remote.verifyCode(phone: phone, code: code);
      await _tokenStorage.saveTokens(
        access: res.tokens.access,
        refresh: res.tokens.refresh,
      );
      return AuthResult(user: res.user, isNew: res.isNew);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _remote.obtainToken(phone: phone, password: password);
      await _tokenStorage.saveTokens(
        access: res.tokens.access,
        refresh: res.tokens.refresh,
      );
      // Don't rely on /auth/token/ returning the user — fetch it from /profile/.
      return await _remote.getCurrentUser();
    } catch (e, st) {
      AppLogger.e('loginWithPassword error: ${e.runtimeType}', error: e, stackTrace: st);
      throw failureFromException(e);
    }
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _remote.loginEmail(email: email, password: password);
      await _tokenStorage.saveTokens(
        access: res.tokens.access,
        refresh: res.tokens.refresh,
      );
      return AuthResult(user: res.user, isNew: res.isNew);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _remote.registerEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      await _tokenStorage.saveTokens(
        access: res.tokens.access,
        refresh: res.tokens.refresh,
      );
      return AuthResult(user: res.user, isNew: res.isNew);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final tokens = await _remote.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (tokens != null) {
        await _tokenStorage.saveTokens(
          access: tokens.access,
          refresh: tokens.refresh,
        );
      }
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<AuthUser> changeEmail(String newEmail) async {
    try {
      return await _remote.changeEmail(newEmail);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PasswordResetRequest> requestPasswordReset(String email) async {
    try {
      return await _remote.requestPasswordReset(email);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<String> verifyPasswordResetCode({
    required int resetId,
    required String code,
  }) async {
    try {
      return await _remote.verifyPasswordResetCode(
        resetId: resetId,
        code: code,
      );
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _remote.confirmPasswordReset(
        resetToken: resetToken,
        newPassword: newPassword,
      );
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<bool> hasSession() => _tokenStorage.hasSession();

  @override
  Future<void> logout() => _tokenStorage.clear();
}
