import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/guide_file.dart';
import '../../domain/repositories/guide_repository.dart';
import '../datasources/guide_remote_data_source.dart';

class GuideRepositoryImpl implements GuideRepository {
  GuideRepositoryImpl(this._remote);

  final GuideRemoteDataSource _remote;

  @override
  Future<List<GuideFile>> getGuideFiles() async {
    try {
      final files = await _remote.getGuideFiles();
      // Defensive ordering by `order`, then newest first.
      final sorted = [...files]..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          if (byOrder != 0) return byOrder;
          final ad = a.createdAt;
          final bd = b.createdAt;
          if (ad == null || bd == null) return 0;
          return bd.compareTo(ad);
        });
      return sorted;
    } catch (e) {
      throw failureFromException(e);
    }
  }
}
