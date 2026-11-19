import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/vehicle_model.dart';

/// HTTP access to the vehicles endpoints. Throws an [AppException] on failure.
abstract class VehicleRemoteDataSource {
  Future<List<VehicleModel>> fetchVehicles();
  Future<VehicleModel> createVehicle(VehicleModel vehicle);
  Future<VehicleModel> updateVehicle(int id, VehicleModel vehicle);
  Future<void> deleteVehicle(int id);
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  VehicleRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<VehicleModel>> fetchVehicles() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.vehicles);
      return (res.data ?? const [])
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<VehicleModel> createVehicle(VehicleModel vehicle) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.vehicles,
        data: vehicle.toJson(),
      );
      return VehicleModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<VehicleModel> updateVehicle(int id, VehicleModel vehicle) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.vehicle(id),
        data: vehicle.toJson(),
      );
      return VehicleModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<void> deleteVehicle(int id) async {
    try {
      await _dio.delete<dynamic>(ApiEndpoints.vehicle(id));
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }
}
