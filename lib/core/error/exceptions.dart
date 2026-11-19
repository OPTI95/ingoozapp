/// Low-level exceptions thrown by the data layer (datasources).
/// These are caught in repositories and converted into [Failure]s.
library;

class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AppException($statusCode): $message';
}

/// Server returned a non-2xx response.
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// Request failed before reaching the server (no internet, timeout).
class NetworkException extends AppException {
  const NetworkException([super.message = 'Нет подключения к интернету']);
}

/// 401 / 403 — token missing, invalid or expired and refresh failed.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Сессия истекла. Войдите снова.'])
      : super(statusCode: 401);
}

/// Response body could not be parsed into the expected shape.
class ParsingException extends AppException {
  const ParsingException([super.message = 'Некорректный ответ сервера']);
}
