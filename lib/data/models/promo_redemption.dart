class PromoRedemption {
  const PromoRedemption({
    required this.id,
    required this.code,
    required this.waybillQuota,
    required this.redeemedAt,
  });

  final String id;
  final String code;
  final int waybillQuota;
  final DateTime redeemedAt;

  factory PromoRedemption.fromMap(Map<String, dynamic> map) {
    final promoCode = map['promo_code'];
    return PromoRedemption(
      id: map['id'] as String,
      code: promoCode is Map<String, dynamic>
          ? (promoCode['code'] as String).toUpperCase()
          : (map['code'] as String?)?.toUpperCase() ?? '—',
      waybillQuota: promoCode is Map<String, dynamic>
          ? (promoCode['waybill_quota'] as int? ?? 0)
          : (map['waybill_quota'] as int? ?? 0),
      redeemedAt: DateTime.parse(map['redeemed_at'] as String),
    );
  }
}
