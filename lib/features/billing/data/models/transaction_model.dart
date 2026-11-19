import '../../domain/entities/transaction.dart';

class TransactionModel extends BalanceTransaction {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.kind,
    super.kindDisplay,
    super.comment,
    super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: double.tryParse('${json['amount']}') ?? 0,
      kind: json['kind'] as String? ?? '',
      kindDisplay: json['kind_display'] as String?,
      comment: json['comment'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
