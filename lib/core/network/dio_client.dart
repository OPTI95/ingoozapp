import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';

/// Builds the single, app-wide [Dio] instance with auth + logging.
class DioClient {
  DioClient._();

  static Dio create(TokenStorage tokenStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        // We handle non-2xx ourselves via interceptors/error mapper.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 100,
      ),
    ]);

    return dio;
  }
}
