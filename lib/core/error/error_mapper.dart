import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failure.dart';

/// Converts a [DioException] (thrown by Dio) into a typed [AppException]
/// for the data layer. Datasources call this; repositories then map the
/// exception to a [Failure] via [failureFromException].
AppException exceptionFromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('Превышено время ожидания сервера');
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badCertificate:
      return const NetworkException('Ошибка сертификата соединения');
    case DioExceptionType.cancel:
      return const NetworkException('Запрос отменён');
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return UnauthorizedException(_messageFromResponse(e.response) ??
            'Сессия истекла. Войдите снова.');
      }
      return ServerException(
        _messageFromResponse(e.response) ?? 'Ошибка сервера',
        statusCode: status,
      );
  }
}

/// Maps a data-layer [AppException] to a presentation [Failure].
Failure failureFromException(Object error) {
  if (error is UnauthorizedException) {
    return UnauthorizedFailure(error.message);
  }
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }
  if (error is ServerException) {
    return ServerFailure(error.message, statusCode: error.statusCode);
  }
  if (error is ParsingException) {
    return ServerFailure(error.message);
  }
  if (error is DioException) {
    return failureFromException(exceptionFromDio(error));
  }
  return const UnknownFailure();
}

/// Best-effort extraction of a human message from a DRF-style error body.
String? _messageFromResponse(Response<dynamic>? response) {
  final raw = _rawMessageFromResponse(response);
  if (raw == null) return null;
  return _localize(raw);
}

String? _rawMessageFromResponse(Response<dynamic>? response) {
  final data = response?.data;
  if (data is Map) {
    for (final key in const ['detail', 'error', 'message']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    // DRF field errors: {"phone": ["Обязательное поле."]}
    for (final value in data.values) {
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
      if (value is String && value.isNotEmpty) return value;
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

/// Replaces well-known server messages (English SimpleJWT/DRF output and
/// common variations) with friendly russian wording. Unknown messages pass
/// through unchanged.
String _localize(String message) {
  final lower = message.toLowerCase();

  // Bad credentials.
  if (lower.contains('no active account') ||
      lower.contains('invalid credentials') ||
      lower.contains('invalid_credentials') ||
      lower.contains('unable to log in') ||
      lower.contains('incorrect password') ||
      lower.contains('wrong password') ||
      lower.contains('invalid login') ||
      lower.contains('неверные учётные') ||
      lower.contains('неверные учетные')) {
    return 'Неверный номер или пароль';
  }
  if (lower.contains('user not found') || lower.contains('not found')) {
    return 'Пользователь не найден';
  }
  if (lower.contains('user is inactive') ||
      lower.contains('account disabled')) {
    return 'Аккаунт заблокирован';
  }
  if (lower.contains('token is invalid') ||
      lower.contains('token_not_valid') ||
      lower.contains('token has expired') ||
      lower.contains('token expired')) {
    return 'Сессия истекла. Войдите снова.';
  }
  return message;
}
