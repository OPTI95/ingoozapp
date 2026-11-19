import 'package:equatable/equatable.dart';

/// Pre-issue cost preview (`POST /waybills/quote/`): how much a waybill for a
/// given vehicle costs, plus the user's current balance and gift waybills.
class WaybillQuote extends Equatable {
  const WaybillQuote({
    required this.cost,
    required this.balance,
    required this.promoWaybillsLeft,
  });

  final double cost;
  final double balance;
  final int promoWaybillsLeft;

  /// Whether the user can issue: a gift waybill is available, or the balance
  /// covers the cost.
  bool get canIssue => promoWaybillsLeft > 0 || balance >= cost;

  @override
  List<Object?> get props => [cost, balance, promoWaybillsLeft];
}
