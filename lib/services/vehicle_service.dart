import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_client.dart';

/// Service for vehicle-related API operations
/// Handles vehicle availability checking via API
class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Check vehicle availability via API
  /// Returns [VehicleCheckResponse] with availability status
  Future<VehicleCheckResponse> checkVehicleAvailability(
    String vehicleId,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.vehicleCheckEndpoint(vehicleId),
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return VehicleCheckResponse.fromJson(response.data!);
      } else {
        throw ApiError(
          statusCode: 404,
          message: response.message ?? 'Kendaraan tidak ditemukan',
        );
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        statusCode: 0,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Check if a vehicle is available for use
  /// Returns true if available, false otherwise
  Future<bool> isVehicleAvailable(String vehicleId) async {
    try {
      final response = await checkVehicleAvailability(vehicleId);
      return response.isAvailable;
    } catch (e) {
      return false;
    }
  }
}

/// Response from GET /vehicles/{vehicleId}/check endpoint
class VehicleCheckResponse {
  final String vehicleId;
  final String licensePlate;
  final bool isAvailable;
  final String status; // Available, In Use
  final VehicleCurrentDriver? currentDriver;
  final VehicleCurrentJobOrder? currentJobOrder;

  VehicleCheckResponse({
    required this.vehicleId,
    required this.licensePlate,
    required this.isAvailable,
    required this.status,
    this.currentDriver,
    this.currentJobOrder,
  });

  factory VehicleCheckResponse.fromJson(Map<String, dynamic> json) {
    return VehicleCheckResponse(
      vehicleId: json['vehicle_id'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      isAvailable: json['is_available'] ?? false,
      status: json['status'] ?? 'Unknown',
      currentDriver:
          json['current_driver'] != null
              ? VehicleCurrentDriver.fromJson(json['current_driver'])
              : null,
      currentJobOrder:
          json['current_job_order'] != null
              ? VehicleCurrentJobOrder.fromJson(json['current_job_order'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'license_plate': licensePlate,
      'is_available': isAvailable,
      'status': status,
      'current_driver': currentDriver?.toJson(),
      'current_job_order': currentJobOrder?.toJson(),
    };
  }
}

/// Current driver using the vehicle
class VehicleCurrentDriver {
  final String driverId;
  final String driverName;

  VehicleCurrentDriver({required this.driverId, required this.driverName});

  factory VehicleCurrentDriver.fromJson(Map<String, dynamic> json) {
    return VehicleCurrentDriver(
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'driver_id': driverId, 'driver_name': driverName};
  }
}

/// Current job order using the vehicle
class VehicleCurrentJobOrder {
  final String jobOrderId;
  final String status;

  VehicleCurrentJobOrder({required this.jobOrderId, required this.status});

  factory VehicleCurrentJobOrder.fromJson(Map<String, dynamic> json) {
    return VehicleCurrentJobOrder(
      jobOrderId: json['job_order_id'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'job_order_id': jobOrderId, 'status': status};
  }
}