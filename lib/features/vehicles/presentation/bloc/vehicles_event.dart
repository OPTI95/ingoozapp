part of 'vehicles_bloc.dart';

sealed class VehiclesEvent extends Equatable {
  const VehiclesEvent();

  @override
  List<Object?> get props => [];
}

/// Load the list (`GET /vehicles/`).
class VehiclesLoadRequested extends VehiclesEvent {
  const VehiclesLoadRequested();
}

/// Delete a vehicle (`DELETE /vehicles/{id}/`).
class VehicleDeleteRequested extends VehiclesEvent {
  const VehicleDeleteRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
