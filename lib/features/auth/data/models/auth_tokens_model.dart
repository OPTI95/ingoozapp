import '../../domain/entities/auth_tokens.dart';

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({required super.access, required super.refresh});

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      access: json['access'] as String? ?? '',
      refresh: json['refresh'] as String? ?? '',
    );
  }
}
