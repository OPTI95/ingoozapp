import '../../domain/entities/owner_type.dart';
import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    super.id,
    required super.displayName,
    required super.plateNumber,
    required super.ownerType,
    super.ownerTypeOtherLabel,
    super.fullName,
    super.vin,
    super.stsNumber,
    super.insuranceNumber,
    super.ownerName,
    super.ownerAddress,
    super.licenseType,
    super.licenseTypeOtherLabel,
    super.licenseOrgName,
    super.licenseAddress,
    super.licensePhone,
    super.licenseNumber,
    super.licenseOgrn,
    super.licenseInn,
    super.licenseIssuedAt,
    super.isActive,
    super.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final rawOwnerType = json['owner_type'] as String?;
    return VehicleModel(
      id: (json['id'] as num?)?.toInt(),
      displayName: json['display_name'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      ownerType: OwnerTypeX.fromValue(rawOwnerType),
      ownerTypeOtherLabel: OwnerTypeX.otherLabelFromValue(rawOwnerType),
      fullName: json['full_name'] as String?,
      vin: json['vin'] as String?,
      stsNumber: json['sts_number'] as String?,
      insuranceNumber: json['insurance_number'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerAddress: json['owner_address'] as String?,
      licenseType: json['license_type'] as String?,
      licenseTypeOtherLabel: json['license_type_other_label'] as String?,
      licenseOrgName: json['license_org_name'] as String?,
      licenseAddress: json['license_address'] as String?,
      licensePhone: json['license_phone'] as String?,
      licenseNumber: json['license_number'] as String?,
      licenseOgrn: json['license_ogrn'] as String?,
      licenseInn: json['license_inn'] as String?,
      licenseIssuedAt: _date(json['license_issued_at']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _date(json['created_at']),
    );
  }

  /// Writable payload for POST/PUT (excludes server-managed id/full_name/created_at).
  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'plate_number': plateNumber,
      'vin': vin,
      'sts_number': stsNumber,
      'insurance_number': insuranceNumber,
      'owner_type':
          OwnerTypeX.encodeValue(ownerType, otherLabel: ownerTypeOtherLabel),
      'owner_name': ownerName,
      'owner_address': ownerAddress,
      'license_type': licenseType,
      'license_type_other_label': licenseTypeOtherLabel,
      'license_org_name': licenseOrgName,
      'license_address': licenseAddress,
      'license_phone': licensePhone,
      'license_number': licenseNumber,
      'license_ogrn': licenseOgrn,
      'license_inn': licenseInn,
      'license_issued_at': _dateToApi(licenseIssuedAt),
      'is_active': isActive,
    };
  }

  factory VehicleModel.fromEntity(Vehicle v) {
    return VehicleModel(
      id: v.id,
      displayName: v.displayName,
      plateNumber: v.plateNumber,
      ownerType: v.ownerType,
      ownerTypeOtherLabel: v.ownerTypeOtherLabel,
      fullName: v.fullName,
      vin: v.vin,
      stsNumber: v.stsNumber,
      insuranceNumber: v.insuranceNumber,
      ownerName: v.ownerName,
      ownerAddress: v.ownerAddress,
      licenseType: v.licenseType,
      licenseTypeOtherLabel: v.licenseTypeOtherLabel,
      licenseOrgName: v.licenseOrgName,
      licenseAddress: v.licenseAddress,
      licensePhone: v.licensePhone,
      licenseNumber: v.licenseNumber,
      licenseOgrn: v.licenseOgrn,
      licenseInn: v.licenseInn,
      licenseIssuedAt: v.licenseIssuedAt,
      isActive: v.isActive,
      createdAt: v.createdAt,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static String? _dateToApi(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
