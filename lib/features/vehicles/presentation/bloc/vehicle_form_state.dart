part of 'vehicle_form_bloc.dart';

enum VehicleFormStatus { idle, submitting, success, failure }

class VehicleFormState extends Equatable {
  const VehicleFormState({
    this.status = VehicleFormStatus.idle,
    this.vehicle,
    this.errorMessage,
  });

  final VehicleFormStatus status;
  final Vehicle? vehicle;
  final String? errorMessage;

  bool get isSubmitting => status == VehicleFormStatus.submitting;

  VehicleFormState copyWith({
    VehicleFormStatus? status,
    Vehicle? vehicle,
    String? errorMessage,
  }) {
    return VehicleFormState(
      status: status ?? this.status,
      vehicle: vehicle ?? this.vehicle,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, vehicle, errorMessage];
}
