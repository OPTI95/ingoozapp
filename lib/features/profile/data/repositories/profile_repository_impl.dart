import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Profile> getProfile() async {
    try {
      return await _remote.getProfile();
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Profile> updateProfile({
    String? email,
    String? fullName,
    DateTime? birthDate,
    String? driverLicenseNumber,
    DateTime? driverLicenseValidFrom,
    DateTime? driverLicenseValidTo,
    String? snils,
  }) async {
    try {
      // Only send fields the caller actually provided (PATCH semantics).
      final body = <String, dynamic>{
        if (email != null) 'email': email,
        if (fullName != null) 'full_name': fullName,
        if (birthDate != null) 'birth_date': ProfileModel.dateToApi(birthDate),
        if (driverLicenseNumber != null)
          'driver_license_number': driverLicenseNumber,
        if (driverLicenseValidFrom != null)
          'driver_license_valid_from':
              ProfileModel.dateToApi(driverLicenseValidFrom),
        if (driverLicenseValidTo != null)
          'driver_license_valid_to':
              ProfileModel.dateToApi(driverLicenseValidTo),
        if (snils != null) 'snils': snils,
      };
      return await _remote.patchProfile(body);
    } catch (e) {
      throw failureFromException(e);
    }
  }
}
