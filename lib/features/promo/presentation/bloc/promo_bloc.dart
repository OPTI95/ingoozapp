import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/promo_redemption.dart';
import '../../domain/repositories/promo_repository.dart';

part 'promo_event.dart';
part 'promo_state.dart';

/// Drives the promo screen: shows gift-waybill credits (from the profile)
/// and the redemption history, and activates new codes.
class PromoBloc extends Bloc<PromoEvent, PromoState> {
  PromoBloc({
    required PromoRepository promoRepository,
    required ProfileRepository profileRepository,
  })  : _promo = promoRepository,
        _profile = profileRepository,
        super(const PromoState()) {
    on<PromoStarted>(_onStarted);
    on<PromoApplied>(_onApplied);
  }

  final PromoRepository _promo;
  final ProfileRepository _profile;

  /// Best-effort credits read; never fails the screen on its own.
  Future<int> _readCredits() async {
    try {
      final profile = await _profile.getProfile();
      return profile.promoWaybillsLeft;
    } on Failure {
      return state.credits;
    }
  }

  Future<void> _onStarted(
    PromoStarted event,
    Emitter<PromoState> emit,
  ) async {
    emit(state.copyWith(status: PromoStatus.loading));
    try {
      final redemptions = await _promo.getRedemptions();
      final credits = await _readCredits();
      emit(state.copyWith(
        status: PromoStatus.ready,
        credits: credits,
        redemptions: redemptions,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: PromoStatus.failure,
        errorMessage: f.message,
      ));
    }
  }

  Future<void> _onApplied(
    PromoApplied event,
    Emitter<PromoState> emit,
  ) async {
    if (event.code.trim().isEmpty) {
      emit(state.copyWith(
        apply: PromoApplyStatus.failure,
        errorMessage: 'Введите промокод',
      ));
      return;
    }
    emit(state.copyWith(apply: PromoApplyStatus.inProgress));
    try {
      await _promo.applyCode(event.code);
      final redemptions = await _promo.getRedemptions();
      final credits = await _readCredits();
      emit(state.copyWith(
        status: PromoStatus.ready,
        apply: PromoApplyStatus.success,
        credits: credits,
        redemptions: redemptions,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        apply: PromoApplyStatus.failure,
        errorMessage: f.message,
      ));
    }
  }
}
