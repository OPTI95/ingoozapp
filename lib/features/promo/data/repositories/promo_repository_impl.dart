import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/promo_redemption.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/promo_remote_data_source.dart';

class PromoRepositoryImpl implements PromoRepository {
  PromoRepositoryImpl(this._remote);

  final PromoRemoteDataSource _remote;

  @override
  Future<PromoRedemption> applyCode(String code) async {
    try {
      return await _remote.applyCode(code.trim().toUpperCase());
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<PromoRedemption>> getRedemptions() async {
    try {
      return await _remote.getRedemptions();
    } catch (e) {
      throw failureFromException(e);
    }
  }
}
