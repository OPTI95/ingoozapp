import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// Result of a successful code verification: the user plus whether the
/// account was just created (drives "set password" onboarding).
class AuthResult extends Equatable {
  const AuthResult({required this.user, required this.isNew});

  final AuthUser user;
  final bool isNew;

  @override
  List<Object?> get props => [user, isNew];
}
