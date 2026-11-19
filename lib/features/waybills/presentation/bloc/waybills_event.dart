part of 'waybills_bloc.dart';

sealed class WaybillsEvent extends Equatable {
  const WaybillsEvent();

  @override
  List<Object?> get props => [];
}

/// Load issued-waybill history (`GET /waybills/`).
class WaybillsLoadRequested extends WaybillsEvent {
  const WaybillsLoadRequested();
}
