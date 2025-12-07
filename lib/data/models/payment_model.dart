class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.providerPaymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final int amount;
  final String currency;
  final String status;
  final String? provider;
  final String? providerPaymentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amount: map['amount'] as int,
      currency: map['currency'] as String,
      status: map['status'] as String,
      provider: map['provider'] as String?,
      providerPaymentId: map['provider_payment_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}
