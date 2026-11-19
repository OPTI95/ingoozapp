import 'package:equatable/equatable.dart';

/// A balance operation (`GET /transactions/`).
class BalanceTransaction extends Equatable {
  const BalanceTransaction({
    required this.id,
    required this.amount,
    required this.kind,
    this.kindDisplay,
    this.comment,
    this.createdAt,
  });

  final int id;
  final double amount;
  final String kind;
  final String? kindDisplay;
  final String? comment;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, amount, kind, kindDisplay, comment, createdAt];
}
