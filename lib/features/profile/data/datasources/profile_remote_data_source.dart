import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/profile_model.dart';

/// HTTP access to the profile endpoints. Throws an [AppException] on failure.
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> patchProfile(Map<String, dynamic> body);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.profile);
      return ProfileModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<ProfileModel> patchProfile(Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.profile,
        data: body,
      );
      return ProfileModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }
}
