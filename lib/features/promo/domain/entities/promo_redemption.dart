import 'package:equatable/equatable.dart';

/// A redeemed promo code (`/api/v1/promo/`).
class PromoRedemption extends Equatable {
  const PromoRedemption({
    required this.id,
    required this.code,
    required this.waybillQuota,
    this.redeemedAt,
  });

  final int id;
  final String code;

  /// Number of gift waybills granted by this code.
  final int waybillQuota;
  final DateTime? redeemedAt;

  @override
  List<Object?> get props => [id, code, waybillQuota, redeemedAt];
}
