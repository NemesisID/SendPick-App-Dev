class Vehicle {
  final String id;
  final String plateNumber;
  final String brand;
  final String model;
  final String type;
  final bool isAvailable;
  final String driverId;
  final String? currentDriverId;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.type,
    this.isAvailable = true,
    required this.driverId,
    this.currentDriverId,
  });

  // Factory constructor to create a Vehicle instance from a Map
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      type: map['type'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      driverId: map['driverId'] ?? '',
      currentDriverId: map['currentDriverId'],
    );
  }

  // Convert Vehicle instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'brand': brand,
      'model': model,
      'type': type,
      'isAvailable': isAvailable,
      'driverId': driverId,
      'currentDriverId': currentDriverId,
    };
  }
}