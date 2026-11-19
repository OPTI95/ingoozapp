import '../entities/waybill.dart';
import '../entities/waybill_quote.dart';

/// Contract for the waybills feature. Implementations throw a [Failure]
/// (from `core/error`) on any error.
abstract class WaybillRepository {
  /// `GET /waybills/` — issued-waybill history.
  Future<List<Waybill>> fetchWaybills();

  /// `GET /waybills/{id}/`
  Future<Waybill> getWaybill(int id);

  /// `POST /waybills/quote/` — cost preview for the given vehicle.
  Future<WaybillQuote> getQuote(int vehicleId);

  /// `POST /waybills/issue/` — issue a waybill for the given vehicle.
  /// [paymentSource] is "promo" | "balance" (null → server auto-picks).
  Future<Waybill> issueWaybill(
    int vehicleId, {
    int? odometer,
    String? paymentSource,
  });
}
