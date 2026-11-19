part of 'guide_bloc.dart';

enum GuideStatus { initial, loading, success, failure }

class GuideState extends Equatable {
  const GuideState({
    this.status = GuideStatus.initial,
    this.files = const [],
    this.errorMessage,
  });

  final GuideStatus status;
  final List<GuideFile> files;
  final String? errorMessage;

  GuideState copyWith({
    GuideStatus? status,
    List<GuideFile>? files,
    String? errorMessage,
  }) {
    return GuideState(
      status: status ?? this.status,
      files: files ?? this.files,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, files, errorMessage];
}
