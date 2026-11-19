import 'package:equatable/equatable.dart';

/// An issued waybill (путевой лист) as returned by `/api/v1/waybills/`.
/// The server generates the number, dates, cost and PDF.
class Waybill extends Equatable {
  const Waybill({
    required this.id,
    required this.number,
    this.driverFullName,
    this.driverLicenseNumber,
    this.vehicleFullName,
    this.vehiclePlate,
    this.licensee,
    this.issuedAt,
    this.validFrom,
    this.validTo,
    this.startTime,
    this.odometer,
    this.cost = 0,
    this.paymentSource,
    this.pdfUrl,
    this.createdAt,
    // --- Зона 1: собственник (владелец) ТС ---
    this.ownerType,
    this.ownerFullName,
    this.ownerAddress,
    // --- Организация (лицензиат) ---
    this.licenseeName,
    this.licenseeOgrn,
    this.licenseeInn,
    this.licenseeOkpo,
    this.licenseeOkud,
    this.licenseeAddress,
    this.licenseePhone,
    this.licenseeLicenseNumber,
    this.licenseeLicenseIssuedAt,
    // --- Зона 4: медосмотр ---
    this.medicalCheckAt,
  });

  final int id;
  final String number;
  final String? driverFullName;
  final String? driverLicenseNumber;
  final String? vehicleFullName;
  final String? vehiclePlate;

  /// Display string for the licensee (legacy field — kept for the list).
  final String? licensee;

  final DateTime? issuedAt;
  final DateTime? validFrom;
  final DateTime? validTo;
  final DateTime? startTime;
  final int? odometer;
  final double cost;

  /// "promo" | "balance" — how the issue was paid.
  final String? paymentSource;
  final String? pdfUrl;
  final DateTime? createdAt;

  // Зона 1. Собственник.
  final String? ownerType;
  final String? ownerFullName;
  final String? ownerAddress;

  // Организация (лицензиат).
  final String? licenseeName;
  final String? licenseeOgrn;
  final String? licenseeInn;
  final String? licenseeOkpo;
  final String? licenseeOkud;
  final String? licenseeAddress;
  final String? licenseePhone;
  final String? licenseeLicenseNumber;
  final DateTime? licenseeLicenseIssuedAt;

  // Зона 4. Медосмотр.
  final DateTime? medicalCheckAt;

  bool get hasPdf => (pdfUrl ?? '').isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        number,
        driverFullName,
        driverLicenseNumber,
        vehicleFullName,
        vehiclePlate,
        licensee,
        issuedAt,
        validFrom,
        validTo,
        startTime,
        odometer,
        cost,
        paymentSource,
        pdfUrl,
        createdAt,
        ownerType,
        ownerFullName,
        ownerAddress,
        licenseeName,
        licenseeOgrn,
        licenseeInn,
        licenseeOkpo,
        licenseeOkud,
        licenseeAddress,
        licenseePhone,
        licenseeLicenseNumber,
        licenseeLicenseIssuedAt,
        medicalCheckAt,
      ];
}
