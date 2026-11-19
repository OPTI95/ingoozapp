import '../../domain/entities/waybill.dart';

class WaybillModel extends Waybill {
  const WaybillModel({
    required super.id,
    required super.number,
    super.driverFullName,
    super.driverLicenseNumber,
    super.vehicleFullName,
    super.vehiclePlate,
    super.licensee,
    super.issuedAt,
    super.validFrom,
    super.validTo,
    super.startTime,
    super.odometer,
    super.cost,
    super.paymentSource,
    super.pdfUrl,
    super.createdAt,
    super.ownerType,
    super.ownerFullName,
    super.ownerAddress,
    super.licenseeName,
    super.licenseeOgrn,
    super.licenseeInn,
    super.licenseeOkpo,
    super.licenseeOkud,
    super.licenseeAddress,
    super.licenseePhone,
    super.licenseeLicenseNumber,
    super.licenseeLicenseIssuedAt,
    super.medicalCheckAt,
  });

  factory WaybillModel.fromJson(Map<String, dynamic> json) {
    return WaybillModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      number: json['number'] as String? ?? '',
      driverFullName: json['driver_full_name'] as String?,
      driverLicenseNumber: json['driver_license_number'] as String?,
      vehicleFullName: json['vehicle_full_name'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      licensee: json['licensee'] as String?,
      issuedAt: _date(json['issued_at']),
      validFrom: _date(json['valid_from']),
      validTo: _date(json['valid_to']),
      startTime: _date(json['start_time']),
      odometer: (json['odometer'] as num?)?.toInt(),
      cost: double.tryParse('${json['cost']}') ?? 0,
      paymentSource: json['payment_source'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: _date(json['created_at']),
      // Зона 1: собственник.
      ownerType: json['owner_type'] as String?,
      ownerFullName: json['owner_full_name'] as String?,
      ownerAddress: json['owner_address'] as String?,
      // Организация (лицензиат).
      licenseeName: json['licensee_name'] as String?,
      licenseeOgrn: json['licensee_ogrn'] as String?,
      licenseeInn: json['licensee_inn'] as String?,
      licenseeOkpo: json['licensee_okpo'] as String?,
      licenseeOkud: json['licensee_okud'] as String?,
      licenseeAddress: json['licensee_address'] as String?,
      licenseePhone: json['licensee_phone'] as String?,
      licenseeLicenseNumber: json['licensee_license_number'] as String?,
      licenseeLicenseIssuedAt: _date(json['licensee_license_issued_at']),
      // Зона 4: медосмотр.
      medicalCheckAt: _date(json['medical_check_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
