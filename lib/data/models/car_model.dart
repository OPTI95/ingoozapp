enum OwnerType { individual, soleProprietor, legalEntity, other }

extension OwnerTypeX on OwnerType {
  String get value {
    switch (this) {
      case OwnerType.individual:
        return 'individual';
      case OwnerType.soleProprietor:
        return 'sole';
      case OwnerType.legalEntity:
        return 'legal';
      case OwnerType.other:
        return 'other';
    }
  }

  static OwnerType fromValue(String? value) {
    if (value != null && value.startsWith('other')) {
      return OwnerType.other;
    }
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

  static String? otherLabelFromValue(String? value) {
    if (value == null) return null;
    if (!value.startsWith('other:')) return null;
    final label = value.substring('other:'.length).trim();
    return label.isEmpty ? null : label;
  }

  static String encodeValue(OwnerType type, {String? otherLabel}) {
    if (type != OwnerType.other) return type.value;
    final label = otherLabel?.trim();
    if (label == null || label.isEmpty) return 'other';
    return 'other:$label';
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
    this.ownerTypeOtherLabel,
    this.ownerName,
    this.ownerInn,
    this.ownerAddress,
    this.ownerPhone,
    this.vin,
    this.stsNumber,
    this.insuranceNumber,
    this.licenseOrgName,
    this.licenseType,
    this.licenseTypeOtherLabel,
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
  final String? ownerTypeOtherLabel;
  final String? ownerName;
  final String? ownerInn;
  final String? ownerAddress;
  final String? ownerPhone;
  final String? vin;
  final String? stsNumber;
  final String? insuranceNumber;
  final String? licenseOrgName;
  final String? licenseType;
  final String? licenseTypeOtherLabel;
  final String? licenseAddress;
  final String? licensePhone;
  final String? licenseNumber;
  final String? licenseOgrn;
  final String? licenseInn;
  final String? licenseOkud;
  final DateTime? licenseIssuedAt;

  String get ownerTypeStoredValue =>
      OwnerTypeX.encodeValue(ownerType, otherLabel: ownerTypeOtherLabel);

  factory CarModel.fromMap(Map<String, dynamic> map) {
    final rawOwnerType = map['owner_type'] as String?;
    return CarModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      displayName: (map['display_name'] as String?) ?? '',
      plateNumber: (map['plate_number'] as String?) ?? '',
      ownerType: OwnerTypeX.fromValue(rawOwnerType),
      ownerTypeOtherLabel: OwnerTypeX.otherLabelFromValue(rawOwnerType),
      ownerName: map['owner_name'] as String?,
      ownerInn: map['owner_inn'] as String?,
      ownerAddress: map['owner_address'] as String?,
      ownerPhone: map['owner_phone'] as String?,
      vin: map['vin'] as String?,
      stsNumber: map['sts_number'] as String?,
      insuranceNumber: map['insurance_number'] as String?,
      licenseOrgName: map['license_org_name'] as String?,
      licenseType: map['license_type'] as String?,
      licenseTypeOtherLabel: map['license_type_other_label'] as String?,
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
      'owner_type': ownerTypeStoredValue,
      'owner_type_other_label': ownerTypeOtherLabel,
      'owner_name': ownerName,
      'owner_address': ownerAddress,
      'vin': vin,
      'sts_number': stsNumber,
      'insurance_number': insuranceNumber,
      'license_org_name': licenseOrgName,
      'license_type': licenseType,
      'license_type_other_label': licenseTypeOtherLabel,
      'license_address': licenseAddress,
      'license_phone': licensePhone,
      'license_number': licenseNumber,
      'license_ogrn': licenseOgrn,
      'license_inn': licenseInn,
      'license_issued_at': licenseIssuedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'user_id': ownerId,
      'display_name': displayName,
      'plate_number': plateNumber,
      'owner_type': ownerTypeStoredValue,
      'owner_name': ownerName,
      'owner_address': ownerAddress,
      'vin': vin,
      'sts_number': stsNumber,
      'insurance_number': insuranceNumber,
      'license_org_name': licenseOrgName,
      'license_type': licenseType,
      'license_type_other_label': licenseTypeOtherLabel,
      'license_address': licenseAddress,
      'license_phone': licensePhone,
      'license_number': licenseNumber,
      'license_ogrn': licenseOgrn,
      'license_inn': licenseInn,
      'license_issued_at': licenseIssuedAt?.toIso8601String(),
    };
  }

  CarModel copyWith({
    String? displayName,
    String? plateNumber,
    OwnerType? ownerType,
    String? ownerTypeOtherLabel,
    String? ownerName,
    String? ownerInn,
    String? ownerAddress,
    String? ownerPhone,
    String? vin,
    String? stsNumber,
    String? insuranceNumber,
    String? licenseOrgName,
    String? licenseType,
    String? licenseTypeOtherLabel,
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
      ownerTypeOtherLabel: ownerTypeOtherLabel ?? this.ownerTypeOtherLabel,
      ownerName: ownerName ?? this.ownerName,
      ownerInn: ownerInn ?? this.ownerInn,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      vin: vin ?? this.vin,
      stsNumber: stsNumber ?? this.stsNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      licenseOrgName: licenseOrgName ?? this.licenseOrgName,
      licenseType: licenseType ?? this.licenseType,
      licenseTypeOtherLabel:
          licenseTypeOtherLabel ?? this.licenseTypeOtherLabel,
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
