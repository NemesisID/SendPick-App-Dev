/// Helper function to safely parse double values from API
/// Handles both num and String types (API may return "291.10" as string)
double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper function to safely parse int values from API
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Driver model representing authenticated driver data from API
class Driver {
  final String driverId;
  final String driverName;
  final String email;
  final String phone;
  final String status;
  final String shift;
  final double? lastLat;
  final double? lastLng;
  final DriverStatistics? statistics;

  Driver({
    required this.driverId,
    required this.driverName,
    required this.email,
    required this.phone,
    required this.status,
    required this.shift,
    this.lastLat,
    this.lastLng,
    this.statistics,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'Off Duty',
      shift: json['shift'] ?? '',
      lastLat: json['last_lat'] != null ? _parseDouble(json['last_lat']) : null,
      lastLng: json['last_lng'] != null ? _parseDouble(json['last_lng']) : null,
      statistics: json['statistics'] != null
          ? DriverStatistics.fromJson(json['statistics'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'email': email,
      'phone': phone,
      'status': status,
      'shift': shift,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'statistics': statistics?.toJson(),
    };
  }

  /// Check if driver is available
  bool get isAvailable => status == 'Available';

  /// Check if driver is on duty
  bool get isOnDuty => status == 'On Duty';

  /// Check if driver is off duty
  bool get isOffDuty => status == 'Off Duty';

  /// Create a copy with updated fields
  Driver copyWith({
    String? driverId,
    String? driverName,
    String? email,
    String? phone,
    String? status,
    String? shift,
    double? lastLat,
    double? lastLng,
    DriverStatistics? statistics,
  }) {
    return Driver(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      shift: shift ?? this.shift,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      statistics: statistics ?? this.statistics,
    );
  }
}

/// Driver statistics/KPI data
class DriverStatistics {
  final int totalOrders;
  final int totalDelivered;
  final double totalDistanceKm;

  DriverStatistics({
    required this.totalOrders,
    required this.totalDelivered,
    required this.totalDistanceKm,
  });

  factory DriverStatistics.fromJson(Map<String, dynamic> json) {
    return DriverStatistics(
      totalOrders: _parseInt(json['total_orders']),
      totalDelivered: _parseInt(json['total_delivered']),
      totalDistanceKm: _parseDouble(json['total_distance_km']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'total_delivered': totalDelivered,
      'total_distance_km': totalDistanceKm,
    };
  }

  /// Calculate delivery success rate
  double get successRate {
    if (totalOrders == 0) return 0;
    return (totalDelivered / totalOrders) * 100;
  }
}

/// Login response data
class LoginResponse {
  final Driver driver;
  final String token;
  final String tokenType;

  LoginResponse({
    required this.driver,
    required this.token,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      driver: Driver.fromJson(json['driver'] ?? {}),
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}

/// Driver status enum
enum DriverStatus {
  available('Available'),
  onDuty('On Duty'),
  offDuty('Off Duty'),
  inactive('Tidak Aktif');

  final String value;
  const DriverStatus(this.value);

  static DriverStatus fromString(String status) {
    return DriverStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => DriverStatus.offDuty,
    );
  }
}
