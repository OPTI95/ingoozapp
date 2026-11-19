import 'package:equatable/equatable.dart';

/// The current user's full, editable profile (`GET /profile/`).
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.phone,
    this.email,
    this.fullName,
    this.birthDate,
    this.driverLicenseNumber,
    this.driverLicenseValidFrom,
    this.driverLicenseValidTo,
    this.snils,
    this.promoWaybillsLeft = 0,
    this.dateJoined,
    this.balance = 0,
  });

  final int id;
  final String phone;
  final String? email;
  final String? fullName;
  final DateTime? birthDate;
  final String? driverLicenseNumber;
  final DateTime? driverLicenseValidFrom;
  final DateTime? driverLicenseValidTo;
  final String? snils;
  final int promoWaybillsLeft;
  final DateTime? dateJoined;
  final double balance;

  @override
  List<Object?> get props => [
        id,
        phone,
        email,
        fullName,
        birthDate,
        driverLicenseNumber,
        driverLicenseValidFrom,
        driverLicenseValidTo,
        snils,
        promoWaybillsLeft,
        dateJoined,
        balance,
      ];
}
