import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/waybill.dart';
import '../../domain/repositories/waybill_repository.dart';

part 'waybills_event.dart';
part 'waybills_state.dart';

/// Drives the waybills history list.
class WaybillsBloc extends Bloc<WaybillsEvent, WaybillsState> {
  WaybillsBloc(this._repository) : super(const WaybillsState()) {
    on<WaybillsLoadRequested>(_onLoad);
  }

  final WaybillRepository _repository;

  Future<void> _onLoad(
    WaybillsLoadRequested event,
    Emitter<WaybillsState> emit,
  ) async {
    emit(state.copyWith(status: WaybillsStatus.loading));
    try {
      final waybills = await _repository.fetchWaybills();
      emit(state.copyWith(status: WaybillsStatus.success, waybills: waybills));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: WaybillsStatus.failure,
        errorMessage: f.message,
      ));
    }
  }
}
