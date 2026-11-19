import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/balance.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/billing_repository.dart';

part 'top_up_event.dart';
part 'top_up_state.dart';

/// Drives the balance top-up screen: shows the current balance and creates
/// a payment whose `payment_url` the UI then opens.
class TopUpBloc extends Bloc<TopUpEvent, TopUpState> {
  TopUpBloc(this._repository) : super(const TopUpState()) {
    on<TopUpStarted>(_onStarted);
    on<TopUpSubmitted>(_onSubmitted);
  }

  final BillingRepository _repository;

  Future<void> _onStarted(
    TopUpStarted event,
    Emitter<TopUpState> emit,
  ) async {
    emit(state.copyWith(status: TopUpStatus.loadingBalance));
    try {
      final balance = await _repository.getBalance();
      emit(state.copyWith(status: TopUpStatus.ready, balance: balance));
    } on Failure {
      // Balance is informational; let the user top up even if it failed.
      emit(state.copyWith(status: TopUpStatus.ready));
    }
  }

  Future<void> _onSubmitted(
    TopUpSubmitted event,
    Emitter<TopUpState> emit,
  ) async {
    emit(state.copyWith(status: TopUpStatus.creating));
    try {
      final payment = await _repository.createPayment(event.amount);
      emit(state.copyWith(status: TopUpStatus.created, payment: payment));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: TopUpStatus.ready,
        errorMessage: f.message,
      ));
    }
  }
}
