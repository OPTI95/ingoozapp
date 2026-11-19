import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Drives the profile screen: initial load and driver-data save.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
  }

  final ProfileRepository _repository;

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.ready, profile: profile));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: f.message,
      ));
    }
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(submission: ProfileSubmission.inProgress));
    try {
      final profile = await _repository.updateProfile(
        email: event.email,
        fullName: event.fullName,
        birthDate: event.birthDate,
        driverLicenseNumber: event.driverLicenseNumber,
        driverLicenseValidFrom: event.driverLicenseValidFrom,
        driverLicenseValidTo: event.driverLicenseValidTo,
        snils: event.snils,
      );
      emit(state.copyWith(
        status: ProfileStatus.ready,
        profile: profile,
        submission: ProfileSubmission.success,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        submission: ProfileSubmission.failure,
        errorMessage: f.message,
      ));
    }
  }
}
