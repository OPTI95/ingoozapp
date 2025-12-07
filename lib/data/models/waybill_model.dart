class WaybillModel {
  const WaybillModel({
    required this.id,
    required this.userId,
    required this.carId,
    required this.number,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    this.mileage,
    this.zone2,
    this.zone3,
    this.zone4,
    this.isConsumed = false,
  });

  final String id;
  final String userId;
  final String carId;
  final String number;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final int? mileage;
  final Map<String, dynamic>? zone2;
  final Map<String, dynamic>? zone3;
  final Map<String, dynamic>? zone4;
  final bool isConsumed;

  factory WaybillModel.fromMap(Map<String, dynamic> map) {
    return WaybillModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      carId: map['car_id'] as String,
      number: map['number'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      startTime: map['start_time'] as String,
      mileage: map['mileage'] as int?,
      zone2: map['zone2'] as Map<String, dynamic>?,
      zone3: map['zone3'] as Map<String, dynamic>?,
      zone4: map['zone4'] as Map<String, dynamic>?,
      isConsumed: (map['is_consumed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'user_id': ownerId,
      'car_id': carId,
      'number': number,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'start_time': startTime,
      'mileage': mileage,
      'zone2': zone2,
      'zone3': zone3,
      'zone4': zone4,
      'is_consumed': isConsumed,
    };
  }
}
