import '../../domain/entities/promo_redemption.dart';

class PromoRedemptionModel extends PromoRedemption {
  const PromoRedemptionModel({
    required super.id,
    required super.code,
    required super.waybillQuota,
    super.redeemedAt,
  });

  factory PromoRedemptionModel.fromJson(Map<String, dynamic> json) {
    return PromoRedemptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      waybillQuota: (json['waybill_quota'] as num?)?.toInt() ?? 0,
      redeemedAt: _date(json['redeemed_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
