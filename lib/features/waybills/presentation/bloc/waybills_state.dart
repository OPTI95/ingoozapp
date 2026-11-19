part of 'waybills_bloc.dart';

enum WaybillsStatus { initial, loading, success, failure }

class WaybillsState extends Equatable {
  const WaybillsState({
    this.status = WaybillsStatus.initial,
    this.waybills = const [],
    this.errorMessage,
  });

  final WaybillsStatus status;
  final List<Waybill> waybills;
  final String? errorMessage;

  WaybillsState copyWith({
    WaybillsStatus? status,
    List<Waybill>? waybills,
    String? errorMessage,
  }) {
    return WaybillsState(
      status: status ?? this.status,
      waybills: waybills ?? this.waybills,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, waybills, errorMessage];
}
