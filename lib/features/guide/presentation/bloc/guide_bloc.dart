import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/guide_file.dart';
import '../../domain/repositories/guide_repository.dart';

part 'guide_event.dart';
part 'guide_state.dart';

/// Loads the read-only driver-guide document list.
class GuideBloc extends Bloc<GuideEvent, GuideState> {
  GuideBloc(this._repository) : super(const GuideState()) {
    on<GuideLoadRequested>(_onLoad);
  }

  final GuideRepository _repository;

  Future<void> _onLoad(
    GuideLoadRequested event,
    Emitter<GuideState> emit,
  ) async {
    emit(state.copyWith(status: GuideStatus.loading));
    try {
      final files = await _repository.getGuideFiles();
      emit(state.copyWith(status: GuideStatus.success, files: files));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: GuideStatus.failure,
        errorMessage: f.message,
      ));
    }
  }
}
