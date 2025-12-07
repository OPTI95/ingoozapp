/// Basic profile information stored per Supabase user.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.balance = 0,
  });

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final double balance;

  UserProfile copyWith({
    String? name,
    String? phone,
    double? balance,
  }) {
    return UserProfile(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
    );
  }
}
