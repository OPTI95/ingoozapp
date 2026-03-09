import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promo_code.dart';
import '../models/promo_redemption.dart';

class PromoRepository {
  PromoRepository(this._client);

  final SupabaseClient _client;

  /// Redeems a promo code via RPC/Edge function and returns the new credit balance.
  Future<int> redeemCode(String code) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');

    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw ArgumentError('EMPTY_CODE');
    }

    final response = await _client.rpc(
      'redeem_promo_code',
      params: {
        'p_code': normalized,
      },
    );

    dynamic payload = response;
    if (payload is List && payload.isNotEmpty) {
      payload = payload.first;
    }

    if (payload is Map<String, dynamic>) {
      final credits = payload['promo_waybills_left'];
      if (credits is int) {
        return credits;
      }
      if (credits is num) {
        return credits.toInt();
      }
    } else if (payload is int) {
      return payload;
    }

    throw AuthException('Unexpected response from redeem_promo_code');
  }

  Future<List<PromoRedemption>> fetchRedemptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');

    final rows = await _client
        .from('promo_redemptions')
        .select('id, redeemed_at, promo_code:promo_codes (code, waybill_quota)')
        .eq('user_id', userId)
        .order('redeemed_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => PromoRedemption.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromoCode>> fetchAdminPromoCodes() async {
    final rows = await _client
        .from('promo_codes')
        .select()
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => PromoCode.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<PromoCode> createPromoCode({
    required String code,
    required int waybillQuota,
    required DateTime expiresAt,
    int maxRedemptions = 1,
  }) async {
    final normalized = code.trim().toUpperCase();
    final response = await _client
        .from('promo_codes')
        .insert({
          'code': normalized,
          'waybill_quota': waybillQuota,
          'expires_at': expiresAt.toIso8601String(),
          'max_redemptions': maxRedemptions,
        })
        .select()
        .single();

    return PromoCode.fromMap(response as Map<String, dynamic>);
  }

  Future<void> deactivatePromoCode(String promoId) async {
    await _client
        .from('promo_codes')
        .update({'is_active': false})
        .eq('id', promoId);
  }

  Future<void> deletePromoCode(String promoId) async {
    await _client.from('promo_redemptions').delete().eq('promo_code_id', promoId);
    await _client.from('promo_codes').delete().eq('id', promoId);
  }

  Future<PromoCode> updatePromoCode({
    required String promoId,
    required String code,
    required int waybillQuota,
    DateTime? expiresAt,
    required int maxRedemptions,
    bool? isActive,
  }) async {
    final normalized = code.trim().toUpperCase();
    final payload = <String, dynamic>{
      'code': normalized,
      'waybill_quota': waybillQuota,
      'max_redemptions': maxRedemptions,
      'expires_at': expiresAt?.toIso8601String(),
    };
    if (isActive != null) {
      payload['is_active'] = isActive;
    }

    final response = await _client
        .from('promo_codes')
        .update(payload)
        .eq('id', promoId)
        .select()
        .single();

    return PromoCode.fromMap(response as Map<String, dynamic>);
  }
}
