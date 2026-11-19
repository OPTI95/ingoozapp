import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the auth flows (call-code + password). Talks only to [AuthRepository];
/// it never sees Dio or storage. Errors arrive as [Failure] and become
/// [AuthError] states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthCodeRequested>(_onCodeRequested);
    on<AuthCodeVerified>(_onCodeVerified);
    on<AuthPasswordLoginRequested>(_onPasswordLogin);
    on<AuthEmailLoginRequested>(_onEmailLogin);
    on<AuthEmailRegisterRequested>(_onEmailRegister);
    on<AuthLoggedOut>(_onLoggedOut);
  }

  final AuthRepository _repository;

  Future<void> _onCodeRequested(
    AuthCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      await _repository.requestCode(phone: event.phone);
      emit(AuthCodeSent(event.phone));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onCodeVerified(
    AuthCodeVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      final result = await _repository.verifyCode(
        phone: event.phone,
        code: event.code,
      );
      emit(AuthAuthenticated(user: result.user, isNew: result.isNew));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onPasswordLogin(
    AuthPasswordLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      final user = await _repository.loginWithPassword(
        phone: event.phone,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onEmailLogin(
    AuthEmailLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      final result = await _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: result.user, isNew: result.isNew));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onEmailRegister(
    AuthEmailRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      final result = await _repository.signUpWithEmail(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      emit(AuthAuthenticated(user: result.user, isNew: result.isNew));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthInitial());
  }
}
