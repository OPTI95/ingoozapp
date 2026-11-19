part of 'vehicle_form_bloc.dart';

sealed class VehicleFormEvent extends Equatable {
  const VehicleFormEvent();

  @override
  List<Object?> get props => [];
}

/// Submit the form. `vehicle.id == null` creates; otherwise updates.
class VehicleFormSubmitted extends VehicleFormEvent {
  const VehicleFormSubmitted(this.vehicle);
  final Vehicle vehicle;

  @override
  List<Object?> get props => [vehicle];
}
