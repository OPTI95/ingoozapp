import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/car_model.dart';
import '../../../data/repositories/car_repository.dart';
import 'car_form_page.dart';

class CarsListPage extends StatefulWidget {
  const CarsListPage({super.key});

  @override
  State<CarsListPage> createState() => _CarsListPageState();
}

class _CarsListPageState extends State<CarsListPage> {
  late final CarRepository _repository;
  List<CarModel> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseCarRepository(Supabase.instance.client);
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() => _loading = true);
    final cars = await _repository.fetchCars();
    setState(() {
      _cars = cars;
      _loading = false;
    });
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CarFormPage()),
    );
    if (created == true) {
      _loadCars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Автомобили')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final car = _cars[index];
                return ListTile(
                  title: Text(car.displayName.isEmpty
                      ? car.plateNumber
                      : car.displayName),
                  subtitle: Text(car.plateNumber),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _cars.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
