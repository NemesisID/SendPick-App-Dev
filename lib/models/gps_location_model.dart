/// GPS Location model for bulk GPS tracking
/// Based on POST /api/driver/gps/bulk endpoint

class GpsLocation {
  final double lat;
  final double lng;
  final DateTime sentAt;
  final String? orderId;
  final String? vehicleId;

  GpsLocation({
    required this.lat,
    required this.lng,
    required this.sentAt,
    this.orderId,
    this.vehicleId,
  });

  factory GpsLocation.fromJson(Map<String, dynamic> json) {
    return GpsLocation(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
      orderId: json['order_id'],
      vehicleId: json['vehicle_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'sent_at': sentAt.toUtc().toIso8601String(),
      if (orderId != null) 'order_id': orderId,
      if (vehicleId != null) 'vehicle_id': vehicleId,
    };
  }

  /// Create a copy with updated fields
  GpsLocation copyWith({
    double? lat,
    double? lng,
    DateTime? sentAt,
    String? orderId,
    String? vehicleId,
  }) {
    return GpsLocation(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      sentAt: sentAt ?? this.sentAt,
      orderId: orderId ?? this.orderId,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }
}

/// Response from POST /gps/bulk endpoint
class GpsBulkResponse {
  final int totalPoints;

  GpsBulkResponse({required this.totalPoints});

  factory GpsBulkResponse.fromJson(Map<String, dynamic> json) {
    return GpsBulkResponse(
      totalPoints: json['total_points'] ?? 0,
    );
  }
}
