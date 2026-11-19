part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the current profile (`GET /profile/`).
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Save edited driver data (`PATCH /profile/`).
class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({
    this.email,
    this.fullName,
    this.birthDate,
    this.driverLicenseNumber,
    this.driverLicenseValidFrom,
    this.driverLicenseValidTo,
    this.snils,
  });

  final String? email;
  final String? fullName;
  final DateTime? birthDate;
  final String? driverLicenseNumber;
  final DateTime? driverLicenseValidFrom;
  final DateTime? driverLicenseValidTo;
  final String? snils;

  @override
  List<Object?> get props => [
        email,
        fullName,
        birthDate,
        driverLicenseNumber,
        driverLicenseValidFrom,
        driverLicenseValidTo,
        snils,
      ];
}
