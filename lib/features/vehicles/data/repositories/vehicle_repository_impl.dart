import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_data_source.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._remote);

  final VehicleRemoteDataSource _remote;

  @override
  Future<List<Vehicle>> fetchVehicles() async {
    try {
      return await _remote.fetchVehicles();
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      return await _remote.createVehicle(VehicleModel.fromEntity(vehicle));
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final id = vehicle.id;
    if (id == null) {
      throw failureFromException(
        const ServerException('Невозможно обновить: отсутствует id автомобиля'),
      );
    }
    try {
      return await _remote.updateVehicle(id, VehicleModel.fromEntity(vehicle));
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> deleteVehicle(int id) async {
    try {
      await _remote.deleteVehicle(id);
    } catch (e) {
      throw failureFromException(e);
    }
  }
}
