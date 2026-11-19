part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Step 1: request a verification call to [phone] (digits only, e.g. 79991234567).
class AuthCodeRequested extends AuthEvent {
  const AuthCodeRequested(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

/// Step 2: verify the [code] from the call for [phone].
class AuthCodeVerified extends AuthEvent {
  const AuthCodeVerified({required this.phone, required this.code});
  final String phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
}

/// Email + password login (`POST /auth/login/email/`).
class AuthEmailLoginRequested extends AuthEvent {
  const AuthEmailLoginRequested({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Email + password registration (`POST /auth/register/email/`).
class AuthEmailRegisterRequested extends AuthEvent {
  const AuthEmailRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });
  final String email;
  final String password;
  final String fullName;

  @override
  List<Object?> get props => [email, password, fullName];
}

/// Password login for users who already set one.
class AuthPasswordLoginRequested extends AuthEvent {
  const AuthPasswordLoginRequested({
    required this.phone,
    required this.password,
  });
  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone, password];
}

/// Clears the local session.
class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}
