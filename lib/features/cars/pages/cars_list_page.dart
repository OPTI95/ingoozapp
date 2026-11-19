import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../../vehicles/presentation/bloc/vehicles_bloc.dart';
import 'car_form_page.dart';

class CarsListPage extends StatelessWidget {
  const CarsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VehiclesBloc>(
      create: (_) => sl<VehiclesBloc>()..add(const VehiclesLoadRequested()),
      child: const _CarsListView(),
    );
  }
}

class _CarsListView extends StatelessWidget {
  const _CarsListView();

  Future<void> _openForm(BuildContext context, {Vehicle? vehicle}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CarFormPage(vehicle: vehicle)),
    );
    if (result == true && context.mounted) {
      context.read<VehiclesBloc>().add(const VehiclesLoadRequested());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text(
          'Вы действительно хотите удалить ${vehicle.title}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted && vehicle.id != null) {
      context.read<VehiclesBloc>().add(VehicleDeleteRequested(vehicle.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Автомобили'),
      ),
      body: BlocConsumer<VehiclesBloc, VehiclesState>(
        listenWhen: (prev, curr) => curr.actionError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionError!)),
          );
        },
        builder: (context, state) {
          if (state.status == VehiclesStatus.loading &&
              state.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == VehiclesStatus.failure &&
              state.vehicles.isEmpty) {
            return _ErrorView(
              message: state.errorMessage ?? 'Не удалось загрузить список',
              onRetry: () => context
                  .read<VehiclesBloc>()
                  .add(const VehiclesLoadRequested()),
            );
          }
          if (state.vehicles.isEmpty) {
            return const Center(child: Text('Автомобилей пока нет'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final vehicle = state.vehicles[index];
              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openForm(context, vehicle: vehicle),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.title,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vehicle.plateNumber,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/svg/ic-pencil.svg',
                            width: 21,
                            height: 21,
                          ),
                          tooltip: 'Редактировать',
                          onPressed: () =>
                              _openForm(context, vehicle: vehicle),
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/svg/ic-trash.svg',
                            width: 21,
                            height: 21,
                          ),
                          tooltip: 'Удалить',
                          onPressed: () => _confirmDelete(context, vehicle),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => _openForm(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
