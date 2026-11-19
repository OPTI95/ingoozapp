import 'package:equatable/equatable.dart';

import 'owner_type.dart';

/// A vehicle owned by the current user (`/api/v1/vehicles/`).
class Vehicle extends Equatable {
  const Vehicle({
    this.id,
    required this.displayName,
    required this.plateNumber,
    required this.ownerType,
    this.ownerTypeOtherLabel,
    this.fullName,
    this.vin,
    this.stsNumber,
    this.insuranceNumber,
    this.ownerName,
    this.ownerAddress,
    this.licenseType,
    this.licenseTypeOtherLabel,
    this.licenseOrgName,
    this.licenseAddress,
    this.licensePhone,
    this.licenseNumber,
    this.licenseOgrn,
    this.licenseInn,
    this.licenseIssuedAt,
    this.isActive = true,
    this.createdAt,
  });

  /// `null` for a not-yet-created vehicle.
  final int? id;
  final String displayName;
  final String plateNumber;
  final OwnerType ownerType;
  final String? ownerTypeOtherLabel;

  /// Server-computed label (read-only).
  final String? fullName;

  final String? vin;
  final String? stsNumber;
  final String? insuranceNumber;
  final String? ownerName;
  final String? ownerAddress;

  final String? licenseType;
  final String? licenseTypeOtherLabel;
  final String? licenseOrgName;
  final String? licenseAddress;
  final String? licensePhone;
  final String? licenseNumber;
  final String? licenseOgrn;
  final String? licenseInn;
  final DateTime? licenseIssuedAt;

  final bool isActive;
  final DateTime? createdAt;

  String get title => displayName.isNotEmpty ? displayName : plateNumber;

  @override
  List<Object?> get props => [
        id,
        displayName,
        plateNumber,
        ownerType,
        ownerTypeOtherLabel,
        fullName,
        vin,
        stsNumber,
        insuranceNumber,
        ownerName,
        ownerAddress,
        licenseType,
        licenseTypeOtherLabel,
        licenseOrgName,
        licenseAddress,
        licensePhone,
        licenseNumber,
        licenseOgrn,
        licenseInn,
        licenseIssuedAt,
        isActive,
        createdAt,
      ];
}
