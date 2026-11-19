import '../entities/promo_redemption.dart';

/// Contract for the promo feature. Implementations throw a [Failure]
/// (from `core/error`) on any error.
abstract class PromoRepository {
  /// `POST /promo/apply/` — redeem a code, returns the redemption.
  Future<PromoRedemption> applyCode(String code);

  /// `GET /promo/redemptions/` — history of redeemed codes.
  Future<List<PromoRedemption>> getRedemptions();
}
