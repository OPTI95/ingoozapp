class PromoCode {
  const PromoCode({
    required this.id,
    required this.code,
    required this.waybillQuota,
    required this.maxRedemptions,
    required this.redemptionsCount,
    required this.isActive,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String code;
  final int waybillQuota;
  final int maxRedemptions;
  final int redemptionsCount;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  int get remainingRedemptions =>
      (maxRedemptions - redemptionsCount).clamp(0, maxRedemptions);

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isRedeemable => isActive && !isExpired && remainingRedemptions > 0;

  factory PromoCode.fromMap(Map<String, dynamic> map) {
    return PromoCode(
      id: map['id'] as String,
      code: (map['code'] as String).toUpperCase(),
      waybillQuota: map['waybill_quota'] as int,
      maxRedemptions: (map['max_redemptions'] as int?) ?? 1,
      redemptionsCount: (map['redemptions_count'] as int?) ?? 0,
      isActive: (map['is_active'] as bool?) ?? true,
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}
