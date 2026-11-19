part of 'top_up_bloc.dart';

enum TopUpStatus { loadingBalance, ready, creating, created, failure }

class TopUpState extends Equatable {
  const TopUpState({
    this.status = TopUpStatus.loadingBalance,
    this.balance,
    this.payment,
    this.errorMessage,
  });

  final TopUpStatus status;
  final Balance? balance;

  /// The just-created payment (carries `payment_url`).
  final Payment? payment;
  final String? errorMessage;

  bool get isCreating => status == TopUpStatus.creating;

  TopUpState copyWith({
    TopUpStatus? status,
    Balance? balance,
    Payment? payment,
    String? errorMessage,
  }) {
    return TopUpState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      payment: payment ?? this.payment,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, balance, payment, errorMessage];
}
