import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/waybill.dart';
import '../../domain/entities/waybill_quote.dart';
import '../../domain/repositories/waybill_repository.dart';
import '../datasources/waybill_remote_data_source.dart';

class WaybillRepositoryImpl implements WaybillRepository {
  WaybillRepositoryImpl(this._remote);

  final WaybillRemoteDataSource _remote;

  @override
  Future<List<Waybill>> fetchWaybills() async {
    try {
      return await _remote.fetchWaybills();
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Waybill> getWaybill(int id) async {
    try {
      return await _remote.getWaybill(id);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<WaybillQuote> getQuote(int vehicleId) async {
    try {
      return await _remote.getQuote(vehicleId);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Waybill> issueWaybill(
    int vehicleId, {
    int? odometer,
    String? paymentSource,
  }) async {
    try {
      return await _remote.issueWaybill(
        vehicleId,
        odometer: odometer,
        paymentSource: paymentSource,
      );
    } catch (e) {
      throw failureFromException(e);
    }
  }
}
