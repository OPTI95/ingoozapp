import 'package:equatable/equatable.dart';

/// JWT pair issued by the API (`access` short-lived, `refresh` long-lived).
class AuthTokens extends Equatable {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  @override
  List<Object?> get props => [access, refresh];
}
