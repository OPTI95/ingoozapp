import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

part 'vehicle_form_event.dart';
part 'vehicle_form_state.dart';

/// Handles create/update of a single vehicle. Whether it creates or updates
/// is decided by `vehicle.id` (null → create).
class VehicleFormBloc extends Bloc<VehicleFormEvent, VehicleFormState> {
  VehicleFormBloc(this._repository) : super(const VehicleFormState()) {
    on<VehicleFormSubmitted>(_onSubmit);
  }

  final VehicleRepository _repository;

  Future<void> _onSubmit(
    VehicleFormSubmitted event,
    Emitter<VehicleFormState> emit,
  ) async {
    emit(state.copyWith(status: VehicleFormStatus.submitting));
    try {
      final vehicle = event.vehicle.id == null
          ? await _repository.createVehicle(event.vehicle)
          : await _repository.updateVehicle(event.vehicle);
      emit(state.copyWith(
        status: VehicleFormStatus.success,
        vehicle: vehicle,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: VehicleFormStatus.failure,
        errorMessage: f.message,
      ));
    }
  }
}
