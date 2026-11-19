part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A network request is in flight (drives button spinners).
class AuthInProgress extends AuthState {
  const AuthInProgress();
}

/// The verification call was placed; UI should reveal the code field.
class AuthCodeSent extends AuthState {
  const AuthCodeSent(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// Login/verification succeeded; the session is persisted.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, this.isNew = false});
  final AuthUser user;
  final bool isNew;

  @override
  List<Object?> get props => [user, isNew];
}

/// A recoverable error to show the user; the flow can be retried.
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
