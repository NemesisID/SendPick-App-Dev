import 'dart:async';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/gps_location_model.dart';
import 'api_client.dart';

/// Service for GPS tracking and bulk GPS data sending
/// Handles POST /gps/bulk endpoint
/// Implements batch sending every 30 seconds as recommended
class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  final ApiClient _apiClient = ApiClient();

  // Buffer to store locations before sending
  final List<GpsLocation> _locationBuffer = [];

  // Timer for periodic sending
  Timer? _sendTimer;

  // Current tracking context
  String? _currentOrderId;
  String? _currentVehicleId;

  // Tracking state
  bool _isTracking = false;

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get buffered locations count
  int get bufferCount => _locationBuffer.length;

  /// Send batch GPS data to server
  /// [locations] array of GPS locations to send
  Future<GpsBulkResponse> sendBulkGps(List<GpsLocation> locations) async {
    if (locations.isEmpty) {
      return GpsBulkResponse(totalPoints: 0);
    }

    try {
      final body = {
        'locations': locations.map((loc) => loc.toJson()).toList(),
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.gpsBulkEndpoint,
        body: body,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('GPS: ${locations.length} points sent successfully');
        return GpsBulkResponse.fromJson(response.data!);
      } else {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal mengirim data GPS',
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

  /// Add a location to the buffer
  /// Location will be sent in the next batch
  void addLocation(double lat, double lng, {String? orderId, String? vehicleId}) {
    final location = GpsLocation(
      lat: lat,
      lng: lng,
      sentAt: DateTime.now(),
      orderId: orderId ?? _currentOrderId,
      vehicleId: vehicleId ?? _currentVehicleId,
    );
    _locationBuffer.add(location);
    debugPrint('GPS: Location added to buffer (${_locationBuffer.length} total)');
  }

  /// Flush the buffer - send all buffered locations to server
  /// Returns number of points sent, or -1 if failed
  Future<int> flushBuffer() async {
    if (_locationBuffer.isEmpty) {
      return 0;
    }

    // Copy buffer and clear
    final locationsToSend = List<GpsLocation>.from(_locationBuffer);
    _locationBuffer.clear();

    try {
      final response = await sendBulkGps(locationsToSend);
      return response.totalPoints;
    } catch (e) {
      // If send fails, add locations back to buffer for retry
      _locationBuffer.insertAll(0, locationsToSend);
      debugPrint('GPS: Failed to send, ${locationsToSend.length} points returned to buffer');
      return -1;
    }
  }

  /// Start periodic GPS tracking
  /// Sends GPS data every [intervalSeconds] (default 30 seconds as recommended)
  void startTracking({
    String? orderId,
    String? vehicleId,
    int intervalSeconds = 30,
  }) {
    if (_isTracking) {
      debugPrint('GPS: Tracking already active');
      return;
    }

    _currentOrderId = orderId;
    _currentVehicleId = vehicleId;
    _isTracking = true;

    // Start periodic timer
    _sendTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      await flushBuffer();
    });

    debugPrint('GPS: Tracking started (interval: ${intervalSeconds}s)');
  }

  /// Update tracking context (e.g., when order changes)
  void updateTrackingContext({String? orderId, String? vehicleId}) {
    _currentOrderId = orderId;
    _currentVehicleId = vehicleId;
    debugPrint('GPS: Tracking context updated (order: $orderId, vehicle: $vehicleId)');
  }

  /// Stop GPS tracking
  /// Will flush remaining buffer before stopping
  Future<void> stopTracking({bool flushBeforeStop = true}) async {
    if (!_isTracking) {
      return;
    }

    // Cancel timer
    _sendTimer?.cancel();
    _sendTimer = null;

    // Flush remaining buffer
    if (flushBeforeStop && _locationBuffer.isNotEmpty) {
      await flushBuffer();
    }

    _currentOrderId = null;
    _currentVehicleId = null;
    _isTracking = false;

    debugPrint('GPS: Tracking stopped');
  }

  /// Clear all buffered locations without sending
  void clearBuffer() {
    _locationBuffer.clear();
    debugPrint('GPS: Buffer cleared');
  }

  /// Dispose the service (call on app exit)
  Future<void> dispose() async {
    await stopTracking(flushBeforeStop: true);
  }
}
