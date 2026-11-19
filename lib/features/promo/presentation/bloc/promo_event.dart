part of 'promo_bloc.dart';

sealed class PromoEvent extends Equatable {
  const PromoEvent();

  @override
  List<Object?> get props => [];
}

/// Load promo credits (from profile) and redemption history.
class PromoStarted extends PromoEvent {
  const PromoStarted();
}

/// Redeem a promo code (`POST /promo/apply/`).
class PromoApplied extends PromoEvent {
  const PromoApplied(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}
