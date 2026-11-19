import 'package:equatable/equatable.dart';

/// Current user balance (`GET /balance/`).
class Balance extends Equatable {
  const Balance({required this.amount, this.updatedAt});

  final double amount;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [amount, updatedAt];
}
