part of 'top_up_bloc.dart';

sealed class TopUpEvent extends Equatable {
  const TopUpEvent();

  @override
  List<Object?> get props => [];
}

/// Load the current balance to show on the top-up screen.
class TopUpStarted extends TopUpEvent {
  const TopUpStarted();
}

/// Create a payment for [amount] rubles (`POST /payments/create/`).
class TopUpSubmitted extends TopUpEvent {
  const TopUpSubmitted(this.amount);
  final int amount;

  @override
  List<Object?> get props => [amount];
}
