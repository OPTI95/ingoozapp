import '../entities/vehicle.dart';

/// CRUD over the current user's vehicles. Implementations throw a [Failure]
/// (from `core/error`) on any error.
abstract class VehicleRepository {
  Future<List<Vehicle>> fetchVehicles();
  Future<Vehicle> createVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(int id);
}
