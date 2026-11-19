part of 'promo_bloc.dart';

enum PromoStatus { loading, ready, failure }

/// Status of a code-activation attempt, layered over loaded data.
enum PromoApplyStatus { idle, inProgress, success, failure }

class PromoState extends Equatable {
  const PromoState({
    this.status = PromoStatus.loading,
    this.credits = 0,
    this.redemptions = const [],
    this.apply = PromoApplyStatus.idle,
    this.errorMessage,
  });

  final PromoStatus status;

  /// Gift waybills left (`promo_waybills_left` from profile).
  final int credits;
  final List<PromoRedemption> redemptions;
  final PromoApplyStatus apply;
  final String? errorMessage;

  bool get isApplying => apply == PromoApplyStatus.inProgress;

  PromoState copyWith({
    PromoStatus? status,
    int? credits,
    List<PromoRedemption>? redemptions,
    PromoApplyStatus? apply,
    String? errorMessage,
  }) {
    return PromoState(
      status: status ?? this.status,
      credits: credits ?? this.credits,
      redemptions: redemptions ?? this.redemptions,
      apply: apply ?? this.apply,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, credits, redemptions, apply, errorMessage];
}
