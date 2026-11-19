import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.phone,
    super.email,
    super.fullName,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
    );
  }
}
