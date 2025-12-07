import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/waybill_model.dart';

abstract class WaybillRepository {
  Future<List<WaybillModel>> fetchWaybills();
  Future<WaybillModel> createWaybill(WaybillModel waybill);
}

class SupabaseWaybillRepository implements WaybillRepository {
  SupabaseWaybillRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WaybillModel>> fetchWaybills() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');

    final response = await _client
        .from('waybills')
        .select()
        .eq('user_id', userId)
        .eq('is_consumed', false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => WaybillModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WaybillModel> createWaybill(WaybillModel waybill) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');

    final response = await _client
        .from('waybills')
        .insert(waybill.toInsertMap(ownerId: userId))
        .select()
        .single();

    return WaybillModel.fromMap(response as Map<String, dynamic>);
  }
}
