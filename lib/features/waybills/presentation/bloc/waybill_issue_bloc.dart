import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';
import '../../domain/entities/waybill.dart';
import '../../domain/entities/waybill_quote.dart';
import '../../domain/repositories/waybill_repository.dart';

part 'waybill_issue_event.dart';
part 'waybill_issue_state.dart';

/// Drives the "Новый путевой лист" screen: lists vehicles, previews cost
/// (quote), lets the user pick the payment source and mileage, and issues.
class WaybillIssueBloc extends Bloc<WaybillIssueEvent, WaybillIssueState> {
  WaybillIssueBloc({
    required WaybillRepository waybillRepository,
    required VehicleRepository vehicleRepository,
  })  : _waybills = waybillRepository,
        _vehicles = vehicleRepository,
        super(const WaybillIssueState()) {
    on<WaybillIssueStarted>(_onStarted);
    on<WaybillVehicleChanged>(_onVehicleChanged);
    on<WaybillPaymentSourceChanged>(_onPaymentSourceChanged);
    on<WaybillIssueSubmitted>(_onSubmitted);
  }

  final WaybillRepository _waybills;
  final VehicleRepository _vehicles;

  Future<void> _onStarted(
    WaybillIssueStarted event,
    Emitter<WaybillIssueState> emit,
  ) async {
    emit(state.copyWith(status: WaybillIssueStatus.loadingVehicles));
    try {
      final vehicles = await _vehicles.fetchVehicles();
      if (vehicles.isEmpty) {
        emit(state.copyWith(status: WaybillIssueStatus.ready, vehicles: []));
        return;
      }
      final firstId = vehicles.first.id;
      emit(state.copyWith(
        status: WaybillIssueStatus.ready,
        vehicles: vehicles,
        selectedVehicleId: firstId,
      ));
      if (firstId != null) await _quote(firstId, emit);
    } on Failure catch (f) {
      emit(state.copyWith(
        status: WaybillIssueStatus.failure,
        errorMessage: f.message,
      ));
    }
  }

  Future<void> _onVehicleChanged(
    WaybillVehicleChanged event,
    Emitter<WaybillIssueState> emit,
  ) async {
    emit(state.copyWith(selectedVehicleId: event.vehicleId));
    await _quote(event.vehicleId, emit);
  }

  Future<void> _quote(int vehicleId, Emitter<WaybillIssueState> emit) async {
    emit(state.copyWith(status: WaybillIssueStatus.quoting));
    try {
      final quote = await _waybills.getQuote(vehicleId);
      final defaultSource = quote.promoWaybillsLeft > 0
          ? 'promo'
          : (quote.balance >= quote.cost ? 'balance' : null);
      emit(state.copyWith(
        status: WaybillIssueStatus.ready,
        quote: quote,
        paymentSource: defaultSource,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: WaybillIssueStatus.ready,
        errorMessage: f.message,
      ));
    }
  }

  void _onPaymentSourceChanged(
    WaybillPaymentSourceChanged event,
    Emitter<WaybillIssueState> emit,
  ) {
    emit(state.copyWith(paymentSource: event.source));
  }

  Future<void> _onSubmitted(
    WaybillIssueSubmitted event,
    Emitter<WaybillIssueState> emit,
  ) async {
    final vehicleId = state.selectedVehicleId;
    if (vehicleId == null) return;
    emit(state.copyWith(status: WaybillIssueStatus.issuing));
    try {
      final waybill = await _waybills.issueWaybill(
        vehicleId,
        odometer: event.odometer,
        paymentSource: state.paymentSource,
      );
      emit(state.copyWith(status: WaybillIssueStatus.issued, issued: waybill));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: WaybillIssueStatus.ready,
        errorMessage: f.message,
        insufficientFunds: _isInsufficientFunds(f),
      ));
    }
  }

  /// Heuristic: the server rejected the issue because the balance was too low.
  bool _isInsufficientFunds(Failure f) {
    if (f.statusCode == 402) return true;
    final m = f.message.toLowerCase();
    return m.contains('insufficient') || m.contains('недостаточно средств');
  }
}
