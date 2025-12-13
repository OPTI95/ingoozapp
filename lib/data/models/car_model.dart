enum OwnerType { individual, soleProprietor, legalEntity }

extension OwnerTypeX on OwnerType {
  String get value {
    switch (this) {
      case OwnerType.individual:
        return 'individual';
      case OwnerType.soleProprietor:
        return 'sole';
      case OwnerType.legalEntity:
        return 'legal';
    }
  }

  static OwnerType fromValue(String? value) {
    switch (value) {
      case 'sole':
        return OwnerType.soleProprietor;
      case 'legal':
        return OwnerType.legalEntity;
      case 'individual':
      default:
        return OwnerType.individual;
    }
  }
}

/// Represents a vehicle attached to a specific user.
class CarModel {
  const CarModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.plateNumber,
    required this.ownerType,
    this.vin,
    this.stsNumber,
    this.insuranceNumber,
    this.licenseOrgName,
    this.licenseAddress,
    this.licensePhone,
    this.licenseNumber,
    this.licenseOgrn,
    this.licenseInn,
    this.licenseOkud,
    this.licenseIssuedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String plateNumber;
  final OwnerType ownerType;
  final String? vin;
  final String? stsNumber;
  final String? insuranceNumber;
  final String? licenseOrgName;
  final String? licenseAddress;
  final String? licensePhone;
  final String? licenseNumber;
  final String? licenseOgrn;
  final String? licenseInn;
  final String? licenseOkud;
  final DateTime? licenseIssuedAt;

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      displayName: (map['display_name'] as String?) ?? '',
      plateNumber: (map['plate_number'] as String?) ?? '',
      ownerType: OwnerTypeX.fromValue(map['owner_type'] as String?),
      vin: map['vin'] as String?,
      stsNumber: map['sts_number'] as String?,
      insuranceNumber: map['insurance_number'] as String?,
      licenseOrgName: map['license_org_name'] as String?,
      licenseAddress: map['license_address'] as String?,
      licensePhone: map['license_phone'] as String?,
      licenseNumber: map['license_number'] as String?,
      licenseOgrn: map['license_ogrn'] as String?,
      licenseInn: map['license_inn'] as String?,
      licenseOkud: map['license_okud'] as String?,
      licenseIssuedAt: map['license_issued_at'] != null
          ? DateTime.tryParse(map['license_issued_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'plate_number': plateNumber,
      'owner_type': ownerType.value,
      'vin': vin,
      'sts_number': stsNumber,
      'insurance_number': insuranceNumber,
      'license_org_name': licenseOrgName,
      'license_address': licenseAddress,
      'license_phone': licensePhone,
      'license_number': licenseNumber,
      'license_ogrn': licenseOgrn,
      'license_inn': licenseInn,
      'license_okud': licenseOkud,
      'license_issued_at': licenseIssuedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'user_id': ownerId,
      'display_name': displayName,
      'plate_number': plateNumber,
      'owner_type': ownerType.value,
      'vin': vin,
      'sts_number': stsNumber,
      'insurance_number': insuranceNumber,
      'license_org_name': licenseOrgName,
      'license_address': licenseAddress,
      'license_phone': licensePhone,
      'license_number': licenseNumber,
      'license_ogrn': licenseOgrn,
      'license_inn': licenseInn,
      'license_okud': licenseOkud,
      'license_issued_at': licenseIssuedAt?.toIso8601String(),
    };
  }

  CarModel copyWith({
    String? displayName,
    String? plateNumber,
    OwnerType? ownerType,
    String? vin,
    String? stsNumber,
    String? insuranceNumber,
    String? licenseOrgName,
    String? licenseAddress,
    String? licensePhone,
    String? licenseNumber,
    String? licenseOgrn,
    String? licenseInn,
    String? licenseOkud,
    DateTime? licenseIssuedAt,
  }) {
    return CarModel(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      plateNumber: plateNumber ?? this.plateNumber,
      ownerType: ownerType ?? this.ownerType,
      vin: vin ?? this.vin,
      stsNumber: stsNumber ?? this.stsNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      licenseOrgName: licenseOrgName ?? this.licenseOrgName,
      licenseAddress: licenseAddress ?? this.licenseAddress,
      licensePhone: licensePhone ?? this.licensePhone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseOgrn: licenseOgrn ?? this.licenseOgrn,
      licenseInn: licenseInn ?? this.licenseInn,
      licenseOkud: licenseOkud ?? this.licenseOkud,
      licenseIssuedAt: licenseIssuedAt ?? this.licenseIssuedAt,
    );
  }
}
