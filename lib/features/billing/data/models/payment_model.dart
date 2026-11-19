import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.amount,
    super.currency,
    super.status,
    super.statusDisplay,
    super.paymentUrl,
    super.createdAt,
    super.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: double.tryParse('${json['amount']}') ?? 0,
      currency: json['currency'] as String? ?? 'RUB',
      status: json['status'] as String? ?? 'new',
      statusDisplay: json['status_display'] as String?,
      paymentUrl: json['payment_url'] as String?,
      createdAt: _date(json['created_at']),
      paidAt: _date(json['paid_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
