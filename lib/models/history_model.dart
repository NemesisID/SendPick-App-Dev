/// History models for order history and driver statistics
/// Based on /api/driver/history and /api/driver/history/stats endpoints

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
/// Represents a completed order in history
class HistoryOrder {
  final String jobOrderId;
  final String customerName;
  final String deliveryAddress;
  final String goodsDesc;
  final double goodsWeight;
  final String status;
  final DateTime completedAt;

  HistoryOrder({
    required this.jobOrderId,
    required this.customerName,
    required this.deliveryAddress,
    required this.goodsDesc,
    required this.goodsWeight,
    required this.status,
    required this.completedAt,
  });

  factory HistoryOrder.fromJson(Map<String, dynamic> json) {
    return HistoryOrder(
      jobOrderId: json['job_order_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      goodsDesc: json['goods_desc'] ?? '',
      goodsWeight: _parseDouble(json['goods_weight']),
      status: json['status'] ?? 'Delivered',
      completedAt: DateTime.tryParse(json['completed_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_order_id': jobOrderId,
      'customer_name': customerName,
      'delivery_address': deliveryAddress,
      'goods_desc': goodsDesc,
      'goods_weight': goodsWeight,
      'status': status,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  /// Get formatted weight string
  String get formattedWeight => '${goodsWeight.toStringAsFixed(1)} kg';

  /// Get formatted date string
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${completedAt.day.toString().padLeft(2, '0')} ${months[completedAt.month - 1]} ${completedAt.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    return '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';
  }
}

/// Driver statistics/KPI data from /history/stats
class HistoryStats {
  final int totalDelivered;
  final double totalWeightKg;
  final double totalDistanceKm;
  final int completedThisMonth;
  final double avgDeliveryTimeHours;

  HistoryStats({
    required this.totalDelivered,
    required this.totalWeightKg,
    required this.totalDistanceKm,
    required this.completedThisMonth,
    required this.avgDeliveryTimeHours,
  });

  factory HistoryStats.fromJson(Map<String, dynamic> json) {
    return HistoryStats(
      totalDelivered: _parseInt(json['total_delivered']),
      totalWeightKg: _parseDouble(json['total_weight_kg']),
      totalDistanceKm: _parseDouble(json['total_distance_km']),
      completedThisMonth: _parseInt(json['completed_this_month']),
      avgDeliveryTimeHours: _parseDouble(json['avg_delivery_time_hours']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_delivered': totalDelivered,
      'total_weight_kg': totalWeightKg,
      'total_distance_km': totalDistanceKm,
      'completed_this_month': completedThisMonth,
      'avg_delivery_time_hours': avgDeliveryTimeHours,
    };
  }

  /// Get formatted weight string
  String get formattedWeight => '${totalWeightKg.toStringAsFixed(1)} kg';

  /// Get formatted distance string
  String get formattedDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  /// Get formatted average delivery time
  String get formattedAvgTime {
    if (avgDeliveryTimeHours < 1) {
      return '${(avgDeliveryTimeHours * 60).round()} menit';
    }
    return '${avgDeliveryTimeHours.toStringAsFixed(1)} jam';
  }
}

/// Dummy data generators for testing and documentation
class DummyHistoryData {
  /// Get dummy history orders
  static List<HistoryOrder> getOrders() {
    return [
      HistoryOrder(
        jobOrderId: 'JO-2025-H001',
        customerName: 'Siti Nurhaliza',
        deliveryAddress: 'Jl. Menteng Raya No. 50, Jakarta Pusat 10310',
        goodsDesc: 'Kosmetik & Skincare',
        goodsWeight: 3.0,
        status: 'Delivered',
        completedAt: DateTime(2025, 12, 28, 14, 30),
      ),
      HistoryOrder(
        jobOrderId: 'JO-2025-H002',
        customerName: 'Ahmad Fauzi',
        deliveryAddress: 'Jl. Pondok Indah No. 200, Jakarta Selatan 12310',
        goodsDesc: 'Furniture - Meja Makan Set',
        goodsWeight: 45.0,
        status: 'Delivered',
        completedAt: DateTime(2025, 12, 27, 16, 45),
      ),
      HistoryOrder(
        jobOrderId: 'JO-2025-H003',
        customerName: 'CV. Maju Jaya',
        deliveryAddress: 'Ruko Mangga Dua, Jakarta Utara',
        goodsDesc: 'Komponen Elektronik',
        goodsWeight: 12.0,
        status: 'Delivered',
        completedAt: DateTime(2025, 12, 26, 11, 20),
      ),
      HistoryOrder(
        jobOrderId: 'JO-2025-H004',
        customerName: 'Ibu Hartini',
        deliveryAddress: 'Perumahan Kelapa Gading, Jakarta Utara',
        goodsDesc: 'Peralatan Dapur',
        goodsWeight: 8.5,
        status: 'Delivered',
        completedAt: DateTime(2025, 12, 25, 10, 15),
      ),
      HistoryOrder(
        jobOrderId: 'JO-2025-H005',
        customerName: 'PT. Teknologi Maju',
        deliveryAddress: 'Gedung SCBD Tower, Jakarta Selatan',
        goodsDesc: 'Server & Network Equipment',
        goodsWeight: 35.0,
        status: 'Delivered',
        completedAt: DateTime(2025, 12, 24, 09, 00),
      ),
    ];
  }

  /// Get dummy history stats
  static HistoryStats getStats() {
    return HistoryStats(
      totalDelivered: 156,
      totalWeightKg: 2450.5,
      totalDistanceKm: 1875.3,
      completedThisMonth: 42,
      avgDeliveryTimeHours: 1.5,
    );
  }
}
