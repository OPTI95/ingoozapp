import '../../domain/entities/balance.dart';

class BalanceModel extends Balance {
  const BalanceModel({required super.amount, super.updatedAt});

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      amount: double.tryParse('${json['amount']}') ?? 0,
      updatedAt: _date(json['updated_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
