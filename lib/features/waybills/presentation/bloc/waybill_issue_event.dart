part of 'waybill_issue_bloc.dart';

sealed class WaybillIssueEvent extends Equatable {
  const WaybillIssueEvent();

  @override
  List<Object?> get props => [];
}

/// Load the user's vehicles, select the first one and quote it.
class WaybillIssueStarted extends WaybillIssueEvent {
  const WaybillIssueStarted();
}

/// Change the selected vehicle and re-quote (`POST /waybills/quote/`).
class WaybillVehicleChanged extends WaybillIssueEvent {
  const WaybillVehicleChanged(this.vehicleId);
  final int vehicleId;

  @override
  List<Object?> get props => [vehicleId];
}

/// Pick how to pay: "promo" | "balance".
class WaybillPaymentSourceChanged extends WaybillIssueEvent {
  const WaybillPaymentSourceChanged(this.source);
  final String source;

  @override
  List<Object?> get props => [source];
}

/// Issue the waybill (`POST /waybills/issue/`) for the selected vehicle.
class WaybillIssueSubmitted extends WaybillIssueEvent {
  const WaybillIssueSubmitted({this.odometer});
  final int? odometer;

  @override
  List<Object?> get props => [odometer];
}
