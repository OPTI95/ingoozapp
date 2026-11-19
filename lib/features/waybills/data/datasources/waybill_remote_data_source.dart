import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/waybill_model.dart';
import '../models/waybill_quote_model.dart';

/// HTTP access to the waybills endpoints. Throws an [AppException] on failure.
abstract class WaybillRemoteDataSource {
  Future<List<WaybillModel>> fetchWaybills();
  Future<WaybillModel> getWaybill(int id);
  Future<WaybillQuoteModel> getQuote(int vehicleId);
  Future<WaybillModel> issueWaybill(
    int vehicleId, {
    int? odometer,
    String? paymentSource,
  });
}

class WaybillRemoteDataSourceImpl implements WaybillRemoteDataSource {
  WaybillRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<WaybillModel>> fetchWaybills() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.waybills);
      return (res.data ?? const [])
          .map((e) => WaybillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<WaybillModel> getWaybill(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.waybill(id),
      );
      return WaybillModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<WaybillQuoteModel> getQuote(int vehicleId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.waybillQuote,
        data: {'vehicle_id': vehicleId},
      );
      return WaybillQuoteModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<WaybillModel> issueWaybill(
    int vehicleId, {
    int? odometer,
    String? paymentSource,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.waybillIssue,
        data: {
          'vehicle_id': vehicleId,
          if (odometer != null) 'odometer': odometer,
          if (paymentSource != null) 'payment_source': paymentSource,
        },
      );
      return WaybillModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }
}
