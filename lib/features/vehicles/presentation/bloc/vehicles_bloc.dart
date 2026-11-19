import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

part 'vehicles_event.dart';
part 'vehicles_state.dart';

/// Drives the vehicles list screen (load + delete).
class VehiclesBloc extends Bloc<VehiclesEvent, VehiclesState> {
  VehiclesBloc(this._repository) : super(const VehiclesState()) {
    on<VehiclesLoadRequested>(_onLoad);
    on<VehicleDeleteRequested>(_onDelete);
  }

  final VehicleRepository _repository;

  Future<void> _onLoad(
    VehiclesLoadRequested event,
    Emitter<VehiclesState> emit,
  ) async {
    emit(state.copyWith(status: VehiclesStatus.loading));
    try {
      final vehicles = await _repository.fetchVehicles();
      emit(state.copyWith(status: VehiclesStatus.success, vehicles: vehicles));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: VehiclesStatus.failure,
        errorMessage: f.message,
      ));
    }
  }

  Future<void> _onDelete(
    VehicleDeleteRequested event,
    Emitter<VehiclesState> emit,
  ) async {
    try {
      await _repository.deleteVehicle(event.id);
      final remaining =
          state.vehicles.where((v) => v.id != event.id).toList();
      emit(state.copyWith(
        status: VehiclesStatus.success,
        vehicles: remaining,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(actionError: f.message));
    }
  }
}
