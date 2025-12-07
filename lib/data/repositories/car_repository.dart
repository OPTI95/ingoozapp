import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/car_model.dart';

abstract class CarRepository {
  Future<List<CarModel>> fetchCars();
  Future<CarModel> createCar(CarModel car);
  Future<void> deleteCar(String id);
}

class SupabaseCarRepository implements CarRepository {
  SupabaseCarRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CarModel>> fetchCars() async {
    final response = await _client.from('cars').select();
    return (response as List<dynamic>)
        .map((e) => CarModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CarModel> createCar(CarModel car) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AuthException('Not authenticated');
    final response = await _client
        .from('cars')
        .insert(car.toInsertMap(ownerId: userId))
        .select()
        .single();
    return CarModel.fromMap(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCar(String id) async {
    await _client.from('cars').delete().eq('id', id);
  }
}
