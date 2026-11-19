part of 'waybill_issue_bloc.dart';

enum WaybillIssueStatus {
  loadingVehicles,
  ready,
  quoting,
  issuing,
  issued,
  failure,
}

class WaybillIssueState extends Equatable {
  const WaybillIssueState({
    this.status = WaybillIssueStatus.loadingVehicles,
    this.vehicles = const [],
    this.selectedVehicleId,
    this.quote,
    this.paymentSource,
    this.issued,
    this.errorMessage,
    this.insufficientFunds = false,
  });

  final WaybillIssueStatus status;
  final List<Vehicle> vehicles;
  final int? selectedVehicleId;

  /// Cost preview for [selectedVehicleId].
  final WaybillQuote? quote;

  /// "promo" | "balance" — chosen by the user (or auto default).
  final String? paymentSource;

  final Waybill? issued;
  final String? errorMessage;
  final bool insufficientFunds;

  bool get isQuoting => status == WaybillIssueStatus.quoting;
  bool get isIssuing => status == WaybillIssueStatus.issuing;
  bool get isBusy => isQuoting || isIssuing;

  bool get promoAvailable => (quote?.promoWaybillsLeft ?? 0) > 0;
  bool get balanceAvailable =>
      quote != null && quote!.balance >= quote!.cost;
  bool get canIssue => promoAvailable || balanceAvailable;

  WaybillIssueState copyWith({
    WaybillIssueStatus? status,
    List<Vehicle>? vehicles,
    int? selectedVehicleId,
    WaybillQuote? quote,
    String? paymentSource,
    Waybill? issued,
    String? errorMessage,
    bool? insufficientFunds,
  }) {
    return WaybillIssueState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      quote: quote ?? this.quote,
      paymentSource: paymentSource ?? this.paymentSource,
      issued: issued ?? this.issued,
      errorMessage: errorMessage,
      insufficientFunds: insufficientFunds ?? false,
    );
  }

  @override
  List<Object?> get props => [
        status,
        vehicles,
        selectedVehicleId,
        quote,
        paymentSource,
        issued,
        errorMessage,
        insufficientFunds,
      ];
}
