part of 'vehicles_bloc.dart';

enum VehiclesStatus { initial, loading, success, failure }

class VehiclesState extends Equatable {
  const VehiclesState({
    this.status = VehiclesStatus.initial,
    this.vehicles = const [],
    this.errorMessage,
    this.actionError,
  });

  final VehiclesStatus status;
  final List<Vehicle> vehicles;

  /// Set when the initial load fails.
  final String? errorMessage;

  /// Set transiently when an action (e.g. delete) fails, keeping the list.
  final String? actionError;

  VehiclesState copyWith({
    VehiclesStatus? status,
    List<Vehicle>? vehicles,
    String? errorMessage,
    String? actionError,
  }) {
    return VehiclesState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      errorMessage: errorMessage,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [status, vehicles, errorMessage, actionError];
}
