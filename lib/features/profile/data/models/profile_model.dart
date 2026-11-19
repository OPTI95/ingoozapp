import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.phone,
    super.email,
    super.fullName,
    super.birthDate,
    super.driverLicenseNumber,
    super.driverLicenseValidFrom,
    super.driverLicenseValidTo,
    super.snils,
    super.promoWaybillsLeft,
    super.dateJoined,
    super.balance,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      birthDate: _date(json['birth_date']),
      driverLicenseNumber: json['driver_license_number'] as String?,
      driverLicenseValidFrom: _date(json['driver_license_valid_from']),
      driverLicenseValidTo: _date(json['driver_license_valid_to']),
      snils: json['snils'] as String?,
      promoWaybillsLeft: (json['promo_waybills_left'] as num?)?.toInt() ?? 0,
      dateJoined: _date(json['date_joined']),
      balance: double.tryParse('${json['balance']}') ?? 0,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  /// Serializes a date to the API's `yyyy-MM-dd` form.
  static String? dateToApi(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
