import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/guide_file_model.dart';

/// HTTP access to the guide endpoint. Throws an [AppException] on failure.
abstract class GuideRemoteDataSource {
  Future<List<GuideFileModel>> getGuideFiles();
}

class GuideRemoteDataSourceImpl implements GuideRemoteDataSource {
  GuideRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<GuideFileModel>> getGuideFiles() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.guide);
      return (res.data ?? const [])
          .map((e) => GuideFileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }
}
