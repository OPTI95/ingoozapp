import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_model.dart';

abstract class PaymentRepository {
  Future<List<PaymentModel>> fetchPayments();
  Future<PaymentModel> createPayment({
    required int amount,
    String currency,
    String status,
    String? provider,
    String? providerPaymentId,
  });
}

class SupabasePaymentRepository implements PaymentRepository {
  SupabasePaymentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PaymentModel>> fetchPayments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');

    final response = await _client
        .from('payments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => PaymentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PaymentModel> createPayment({
    required int amount,
    String currency = 'RUB',
    String status = 'succeeded',
    String? provider,
    String? providerPaymentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');

    final response = await _client
        .from('payments')
        .insert({
          'user_id': userId,
          'amount': amount,
          'currency': currency,
          'status': status,
          'provider': provider,
          'provider_payment_id': providerPaymentId,
        })
        .select()
        .single();

    return PaymentModel.fromMap(response as Map<String, dynamic>);
  }
}
