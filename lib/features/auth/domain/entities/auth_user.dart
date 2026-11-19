import 'package:equatable/equatable.dart';

/// Authenticated user as returned by the auth endpoints. The full editable
/// profile lives in the `profile` feature; this is the minimal identity.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    this.email,
    this.fullName,
  });

  final int id;
  final String phone;
  final String? email;
  final String? fullName;

  @override
  List<Object?> get props => [id, phone, email, fullName];
}
