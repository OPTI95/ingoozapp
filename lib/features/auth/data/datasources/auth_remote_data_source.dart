import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/password_reset_request.dart';
import '../models/auth_tokens_model.dart';
import '../models/auth_user_model.dart';

/// Raw response of the verify-code call.
class VerifyResponse {
  const VerifyResponse({
    required this.tokens,
    required this.user,
    required this.isNew,
  });

  final AuthTokensModel tokens;
  final AuthUserModel user;
  final bool isNew;
}

/// Talks to the auth-related HTTP endpoints. Throws an [AppException]
/// (mapped from [DioException]) on any failure — never a raw Dio error.
abstract class AuthRemoteDataSource {
  Future<void> requestCode(String phone);
  Future<VerifyResponse> verifyCode({required String phone, required String code});
  Future<VerifyResponse> obtainToken({required String phone, required String password});
  Future<VerifyResponse> loginEmail({required String email, required String password});
  Future<VerifyResponse> registerEmail({
    required String email,
    required String password,
    required String fullName,
  });
  Future<AuthUserModel> getCurrentUser();

  /// `POST /auth/password/change/`. Optional new token pair may be returned
  /// — `null` if the server replies with an empty body.
  Future<AuthTokensModel?> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// `POST /auth/email/change/`. Returns the updated profile.
  Future<AuthUserModel> changeEmail(String newEmail);

  /// Sends a one-time code to [email] so the user can reset a forgotten
  /// password. Never carries an Authorization header.
  Future<PasswordResetRequest> requestPasswordReset(String email);

  /// Checks the emailed code against the attempt. Returns `reset_token`.
  Future<String> verifyPasswordResetCode({
    required int resetId,
    required String code,
  });

  /// Sets the new password using the token from the verify step (HTTP 204).
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> requestCode(String phone) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.requestCode,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<VerifyResponse> verifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.verifyCode,
        data: {'phone': phone, 'code': code},
      );
      final data = res.data ?? const {};
      return VerifyResponse(
        tokens: AuthTokensModel.fromJson(data),
        user: AuthUserModel.fromJson(
          (data['user'] as Map<String, dynamic>?) ?? const {},
        ),
        isNew: data['is_new'] == true,
      );
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<VerifyResponse> obtainToken({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.token,
        data: {'phone': phone, 'password': password},
      );
      final data = res.data ?? const {};
      return VerifyResponse(
        tokens: AuthTokensModel.fromJson(data),
        user: AuthUserModel.fromJson(
          (data['user'] as Map<String, dynamic>?) ?? const {},
        ),
        isNew: false,
      );
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<VerifyResponse> loginEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.loginEmail,
        data: {'email': email, 'password': password},
      );
      return _parseSession(res.data);
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<VerifyResponse> registerEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.registerEmail,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );
      return _parseSession(res.data);
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<AuthUserModel> getCurrentUser() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.profile);
      return AuthUserModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<AuthTokensModel?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.passwordChange,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      final data = res.data;
      if (data == null || data['access'] == null) return null;
      return AuthTokensModel.fromJson(data);
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<AuthUserModel> changeEmail(String newEmail) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.emailChange,
        data: {'new_email': newEmail},
      );
      return AuthUserModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<PasswordResetRequest> requestPasswordReset(String email) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.passwordResetRequest,
        data: {'email': email},
      );
      final data = res.data ?? const <String, dynamic>{};
      final raw = data['reset_id'];
      final resetId = raw is int ? raw : int.tryParse('$raw');
      final detail = data['detail'];
      return PasswordResetRequest(
        resetId: resetId,
        detail: detail is String ? detail : null,
      );
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<String> verifyPasswordResetCode({
    required int resetId,
    required String code,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.passwordResetVerify,
        data: {'reset_id': resetId, 'code': code},
      );
      final token = (res.data ?? const {})['reset_token'];
      if (token is String && token.isNotEmpty) return token;
      throw const ServerException('Некорректный ответ сервера: нет reset_token');
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.passwordResetConfirm,
        data: {
          'reset_token': resetToken,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  /// Shared parser for `{access, refresh, is_new, user}` payloads.
  VerifyResponse _parseSession(Map<String, dynamic>? data) {
    final json = data ?? const <String, dynamic>{};
    return VerifyResponse(
      tokens: AuthTokensModel.fromJson(json),
      user: AuthUserModel.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const {},
      ),
      isNew: json['is_new'] == true,
    );
  }
}
