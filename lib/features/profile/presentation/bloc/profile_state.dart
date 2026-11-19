part of 'profile_bloc.dart';

/// Status of the initial profile fetch.
enum ProfileStatus { initial, loading, ready, error }

/// Status of a save (`PATCH`) operation, layered over a loaded profile.
enum ProfileSubmission { idle, inProgress, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.submission = ProfileSubmission.idle,
    this.errorMessage,
  });

  final ProfileStatus status;
  final Profile? profile;
  final ProfileSubmission submission;
  final String? errorMessage;

  bool get isLoading => status == ProfileStatus.loading;
  bool get isSaving => submission == ProfileSubmission.inProgress;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    ProfileSubmission? submission,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      submission: submission ?? this.submission,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, submission, errorMessage];
}
