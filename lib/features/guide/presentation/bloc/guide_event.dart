part of 'guide_bloc.dart';

sealed class GuideEvent extends Equatable {
  const GuideEvent();

  @override
  List<Object?> get props => [];
}

/// Load the list of published guide documents (`GET /guide/`).
class GuideLoadRequested extends GuideEvent {
  const GuideLoadRequested();
}
