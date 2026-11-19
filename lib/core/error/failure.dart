import 'package:equatable/equatable.dart';

/// User-facing, presentation-friendly error returned by repositories.
/// Blocs map these to messages/states; they never expose Dio/exceptions to UI.
/// Implements [Exception] so repositories can `throw` it and blocs `catch` it.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет подключения к интернету']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Сессия истекла. Войдите снова.',
  ]) : super(statusCode: 401);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Произошла ошибка. Попробуйте позже.']);
}
