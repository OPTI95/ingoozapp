import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/promo_redemption_model.dart';

/// HTTP access to the promo endpoints. Throws an [AppException] on failure.
abstract class PromoRemoteDataSource {
  Future<PromoRedemptionModel> applyCode(String code);
  Future<List<PromoRedemptionModel>> getRedemptions();
}

class PromoRemoteDataSourceImpl implements PromoRemoteDataSource {
  PromoRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PromoRedemptionModel> applyCode(String code) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.promoApply,
        data: {'code': code},
      );
      return PromoRedemptionModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<List<PromoRedemptionModel>> getRedemptions() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.promoRedemptions,
      );
      return (res.data ?? const [])
          .map((e) => PromoRedemptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }
}
