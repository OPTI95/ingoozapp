import '../entities/guide_file.dart';

/// Contract for the driver-guide feature. Implementations throw a [Failure]
/// (from `core/error`) on any error.
abstract class GuideRepository {
  /// `GET /guide/` — published guide documents, ordered.
  Future<List<GuideFile>> getGuideFiles();
}
