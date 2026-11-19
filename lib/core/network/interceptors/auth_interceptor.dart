import 'dart:async';

import 'package:dio/dio.dart';

import '../../config/env.dart';
import '../../logging/app_logger.dart';
import '../../storage/token_storage.dart';
import '../api_endpoints.dart';

/// Attaches the JWT access token to every request and transparently refreshes
/// it once on a 401, retrying the original request. If refresh fails, the
/// session is cleared and the 401 is propagated so the app can route to login.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  /// Bare Dio used only to refresh — keeps it off the interceptor chain so a
  /// failing refresh can't recurse into another refresh.
  late final Dio _refreshDio = Dio(
    BaseOptions(baseUrl: Env.apiBaseUrl),
  );

  /// Endpoints that must never carry a (possibly stale) Authorization header.
  static const _noAuthPaths = {
    ApiEndpoints.requestCode,
    ApiEndpoints.verifyCode,
    ApiEndpoints.token,
    ApiEndpoints.tokenRefresh,
    ApiEndpoints.loginEmail,
    ApiEndpoints.registerEmail,
    ApiEndpoints.passwordResetRequest,
    ApiEndpoints.passwordResetVerify,
    ApiEndpoints.passwordResetConfirm,
  };

  bool _isAuthFreePath(String path) =>
      _noAuthPaths.any((p) => path.endsWith(p) || path == p);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthFreePath(options.path)) {
      // Login/register/refresh must never carry a stale token. If callers
      // accidentally attached one, drop it here.
      options.headers.remove('Authorization');
    } else {
      final access = await _tokenStorage.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final isRefreshable = status == 401 &&
        !_isAuthFreePath(err.requestOptions.path) &&
        err.requestOptions.extra['__retried__'] != true;

    if (!isRefreshable) {
      return handler.next(err);
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _tokenStorage.clear();
      return handler.next(err);
    }

    try {
      final access = await _tokenStorage.readAccess();
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer $access'
        ..extra['__retried__'] = true;
      final response = await _refreshDio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokenStorage.readRefresh();
    if (refresh == null) return false;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refresh},
      );
      final access = res.data?['access'] as String?;
      if (access == null) return false;
      final newRefresh = res.data?['refresh'] as String?;
      if (newRefresh != null) {
        await _tokenStorage.saveTokens(access: access, refresh: newRefresh);
      } else {
        await _tokenStorage.saveAccess(access);
      }
      AppLogger.i('Access token refreshed');
      return true;
    } on DioException catch (e) {
      AppLogger.w('Token refresh failed: ${e.message}');
      return false;
    }
  }
}
