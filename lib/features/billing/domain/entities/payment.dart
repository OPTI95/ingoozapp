import 'package:equatable/equatable.dart';

/// A balance top-up (`GET /payments/`, `POST /payments/create/`).
class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.amount,
    this.currency = 'RUB',
    this.status = 'new',
    this.statusDisplay,
    this.paymentUrl,
    this.createdAt,
    this.paidAt,
  });

  final int id;
  final double amount;
  final String currency;
  final String status;
  final String? statusDisplay;

  /// Bank page to complete the payment (returned by create).
  final String? paymentUrl;
  final DateTime? createdAt;
  final DateTime? paidAt;

  bool get hasPaymentUrl => (paymentUrl ?? '').isNotEmpty;
  bool get isPaid => paidAt != null || status == 'succeeded' || status == 'paid';

  @override
  List<Object?> get props =>
      [id, amount, currency, status, statusDisplay, paymentUrl, createdAt, paidAt];
}
