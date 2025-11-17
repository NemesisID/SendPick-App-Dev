import 'dart:async';
import 'dart:math';
import '../models/vehicle.dart';

class VehicleService {
  // Simulate vehicles data - in a real app, this would come from an API or database
  static List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      plateNumber: 'B 1234 XY',
      brand: 'Toyota',
      model: 'Avanza',
      type: 'Mobil',
      isAvailable: true,
      driverId: '',
    ),
    Vehicle(
      id: '2',
      plateNumber: 'B 5678 ZW',
      brand: 'Honda',
      model: 'Jazz',
      type: 'Mobil',
      isAvailable: true,
      driverId: '',
    ),
    Vehicle(
      id: '3',
      plateNumber: 'B 9012 AB',
      brand: 'Daihatsu',
      model: 'Xenia',
      type: 'Mobil',
      isAvailable: false,
      driverId: 'driver001',
      currentDriverId: 'driver001',
    ),
    Vehicle(
      id: '4',
      plateNumber: 'B 3456 CD',
      brand: 'Suzuki',
      model: 'Ertiga',
      type: 'Mobil',
      isAvailable: true,
      driverId: '',
    ),
    Vehicle(
      id: '5',
      plateNumber: 'B 7890 EF',
      brand: 'Mitsubishi',
      model: 'Xpander',
      type: 'Mobil',
      isAvailable: true,
      driverId: '',
    ),
  ];

  static List<Vehicle> get availableVehicles {
    return _vehicles.where((vehicle) => vehicle.isAvailable).toList();
  }

  static List<Vehicle> getAllVehicles() {
    return _vehicles;
  }

  // Simulate API call delay
  static Future<List<Vehicle>> fetchAvailableVehicles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _vehicles.where((vehicle) => vehicle.isAvailable).toList();
  }

  static Future<bool> assignVehicleToDriver(String vehicleId, String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
    int index = _vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index != -1) {
      _vehicles[index] = _vehicles[index].copyWith(
        isAvailable: false,
        currentDriverId: driverId,
      );
      return true;
    }
    return false;
  }

  static Future<bool> releaseVehicle(String vehicleId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
    int index = _vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index != -1) {
      _vehicles[index] = _vehicles[index].copyWith(
        isAvailable: true,
        currentDriverId: null,
      );
      return true;
    }
    return false;
  }
}

extension VehicleCopyWith on Vehicle {
  Vehicle copyWith({
    String? id,
    String? plateNumber,
    String? brand,
    String? model,
    String? type,
    bool? isAvailable,
    String? driverId,
    String? currentDriverId,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      type: type ?? this.type,
      isAvailable: isAvailable ?? this.isAvailable,
      driverId: driverId ?? this.driverId,
      currentDriverId: currentDriverId ?? this.currentDriverId,
    );
  }
}