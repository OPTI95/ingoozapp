import '../entities/profile.dart';

/// Contract for reading and updating the current user's profile.
/// Implementations throw a [Failure] (from `core/error`) on any error.
abstract class ProfileRepository {
  /// `GET /profile/`
  Future<Profile> getProfile();

  /// `PATCH /profile/` — only the provided fields are sent.
  Future<Profile> updateProfile({
    String? email,
    String? fullName,
    DateTime? birthDate,
    String? driverLicenseNumber,
    DateTime? driverLicenseValidFrom,
    DateTime? driverLicenseValidTo,
    String? snils,
  });
}
