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

  Future<void> _openForm({CarModel? car}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CarFormPage(car: car)),
    );
    if (result == true) {
      _loadCars();
    }
  }

  Future<void> _confirmDelete(CarModel car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text('Вы действительно хотите удалить ${car.displayName.isEmpty ? car.plateNumber : car.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteCar(car.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Автомобиль удалён')),
      );
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
                final title = car.displayName.isEmpty ? car.plateNumber : car.displayName;
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openForm(car: car),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                                const SizedBox(height: 4),
                                Text(car.plateNumber, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Редактировать',
                            onPressed: () => _openForm(car: car),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Удалить',
                            onPressed: () => _confirmDelete(car),
                          ),
                        ],
                      ),
                    ),
                  ),
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
