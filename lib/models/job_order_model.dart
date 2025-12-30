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

/// Job Order model representing job/order data from API
/// Based on /api/driver/jobs and /api/driver/jobs/{jobOrderId} endpoints
class JobOrder {
  final String jobOrderId;
  final String customerName;
  final String? customerPhone;
  final double pickupLat;
  final double pickupLng;
  final double deliveryLat;
  final double deliveryLng;
  final String pickupAddress;
  final String deliveryAddress;
  final String? pickupContact;
  final String? pickupPhone;
  final String? recipientPhone;
  final String goodsDesc;
  final double goodsWeight;
  final double? goodsVolume;
  final String shipDate;
  final String? deliveryDate;
  final String status; // Processing, In Transit, Pickup Complete, Nearby, Delivered
  final String orderType; // Reguler, Express
  final String? specialInstruction;
  final String? assignmentStatus; // Active, Pending
  final Assignment? assignment;
  final DeliveryOrder? deliveryOrder;
  final ProofOfDelivery? proofOfDelivery;

  JobOrder({
    required this.jobOrderId,
    required this.customerName,
    this.customerPhone,
    required this.pickupLat,
    required this.pickupLng,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.pickupContact,
    this.pickupPhone,
    this.recipientPhone,
    required this.goodsDesc,
    required this.goodsWeight,
    this.goodsVolume,
    required this.shipDate,
    this.deliveryDate,
    required this.status,
    required this.orderType,
    this.specialInstruction,
    this.assignmentStatus,
    this.assignment,
    this.deliveryOrder,
    this.proofOfDelivery,
  });

  factory JobOrder.fromJson(Map<String, dynamic> json) {
    return JobOrder(
      jobOrderId: json['job_order_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'],
      pickupLat: _parseDouble(json['pickup_lat']),
      pickupLng: _parseDouble(json['pickup_lng']),
      deliveryLat: _parseDouble(json['delivery_lat']),
      deliveryLng: _parseDouble(json['delivery_lng']),
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      pickupContact: json['pickup_contact'],
      pickupPhone: json['pickup_phone'],
      recipientPhone: json['recipient_phone'],
      goodsDesc: json['goods_desc'] ?? '',
      goodsWeight: _parseDouble(json['goods_weight']),
      goodsVolume: json['goods_volume'] != null ? _parseDouble(json['goods_volume']) : null,
      shipDate: json['ship_date'] ?? '',
      deliveryDate: json['delivery_date'],
      status: json['status'] ?? 'Processing',
      orderType: json['order_type'] ?? 'Reguler',
      specialInstruction: json['special_instruction'],
      assignmentStatus: json['assignment_status'],
      assignment: json['assignment'] != null
          ? Assignment.fromJson(json['assignment'])
          : null,
      deliveryOrder: json['delivery_order'] != null
          ? DeliveryOrder.fromJson(json['delivery_order'])
          : null,
      proofOfDelivery: json['proof_of_delivery'] != null
          ? ProofOfDelivery.fromJson(json['proof_of_delivery'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_order_id': jobOrderId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'pickup_contact': pickupContact,
      'pickup_phone': pickupPhone,
      'recipient_phone': recipientPhone,
      'goods_desc': goodsDesc,
      'goods_weight': goodsWeight,
      'goods_volume': goodsVolume,
      'ship_date': shipDate,
      'delivery_date': deliveryDate,
      'status': status,
      'order_type': orderType,
      'special_instruction': specialInstruction,
      'assignment_status': assignmentStatus,
      'assignment': assignment?.toJson(),
      'delivery_order': deliveryOrder?.toJson(),
      'proof_of_delivery': proofOfDelivery?.toJson(),
    };
  }

  /// Check if order is active (has been accepted)
  bool get isActive => assignmentStatus == 'Active';

  /// Check if order is pending (waiting for acceptance)
  bool get isPending => assignmentStatus == 'Pending' || assignmentStatus == null;

  /// Check if order is delivered
  bool get isDelivered => status == 'Delivered';

  /// Get formatted weight string
  String get formattedWeight => '${goodsWeight.toStringAsFixed(1)} kg';

  /// Create a copy with updated fields
  JobOrder copyWith({
    String? jobOrderId,
    String? customerName,
    String? customerPhone,
    double? pickupLat,
    double? pickupLng,
    double? deliveryLat,
    double? deliveryLng,
    String? pickupAddress,
    String? deliveryAddress,
    String? pickupContact,
    String? pickupPhone,
    String? recipientPhone,
    String? goodsDesc,
    double? goodsWeight,
    double? goodsVolume,
    String? shipDate,
    String? deliveryDate,
    String? status,
    String? orderType,
    String? specialInstruction,
    String? assignmentStatus,
    Assignment? assignment,
    DeliveryOrder? deliveryOrder,
    ProofOfDelivery? proofOfDelivery,
  }) {
    return JobOrder(
      jobOrderId: jobOrderId ?? this.jobOrderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupContact: pickupContact ?? this.pickupContact,
      pickupPhone: pickupPhone ?? this.pickupPhone,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      goodsDesc: goodsDesc ?? this.goodsDesc,
      goodsWeight: goodsWeight ?? this.goodsWeight,
      goodsVolume: goodsVolume ?? this.goodsVolume,
      shipDate: shipDate ?? this.shipDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      specialInstruction: specialInstruction ?? this.specialInstruction,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      assignment: assignment ?? this.assignment,
      deliveryOrder: deliveryOrder ?? this.deliveryOrder,
      proofOfDelivery: proofOfDelivery ?? this.proofOfDelivery,
    );
  }
}

/// Assignment data for job order
class Assignment {
  final int assignmentId;
  final String status;
  final DateTime assignedAt;

  Assignment({
    required this.assignmentId,
    required this.status,
    required this.assignedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentId: _parseInt(json['assignment_id']),
      status: json['status'] ?? '',
      assignedAt: DateTime.tryParse(json['assigned_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'status': status,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }
}

/// Delivery Order data
class DeliveryOrder {
  final String doId;
  final String status;
  final String pickupLocation;
  final String deliveryLocation;
  final String goodsSummary;

  DeliveryOrder({
    required this.doId,
    required this.status,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.goodsSummary,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      doId: json['do_id'] ?? '',
      status: json['status'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      deliveryLocation: json['delivery_location'] ?? '',
      goodsSummary: json['goods_summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'do_id': doId,
      'status': status,
      'pickup_location': pickupLocation,
      'delivery_location': deliveryLocation,
      'goods_summary': goodsSummary,
    };
  }
}

/// Proof of Delivery data
class ProofOfDelivery {
  final int podId;
  final String doId;
  final String? photoUrl;

  ProofOfDelivery({
    required this.podId,
    required this.doId,
    this.photoUrl,
  });

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    return ProofOfDelivery(
      podId: _parseInt(json['pod_id']),
      doId: json['do_id'] ?? '',
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pod_id': podId,
      'do_id': doId,
      'photo_url': photoUrl,
    };
  }
}

/// Response from GET /jobs endpoint
class JobsResponse {
  final List<JobOrder> activeOrders;
  final List<JobOrder> pendingOrders;

  JobsResponse({
    required this.activeOrders,
    required this.pendingOrders,
  });

  factory JobsResponse.fromJson(Map<String, dynamic> json) {
    return JobsResponse(
      activeOrders: (json['active_orders'] as List<dynamic>?)
              ?.map((e) => JobOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingOrders: (json['pending_orders'] as List<dynamic>?)
              ?.map((e) => JobOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get total count of all orders
  int get totalCount => activeOrders.length + pendingOrders.length;

  /// Check if there are any orders
  bool get hasOrders => totalCount > 0;
}

/// Response from POST /jobs/{id}/accept endpoint
class AcceptOrderResponse {
  final String jobOrderId;
  final int assignmentId;

  AcceptOrderResponse({
    required this.jobOrderId,
    required this.assignmentId,
  });

  factory AcceptOrderResponse.fromJson(Map<String, dynamic> json) {
    return AcceptOrderResponse(
      jobOrderId: json['job_order_id'] ?? '',
      assignmentId: json['assignment_id'] ?? 0,
    );
  }
}

/// Response from POST /jobs/{id}/pod endpoint
class PodUploadResponse {
  final int podId;
  final String doId;
  final String? photoUrl;

  PodUploadResponse({
    required this.podId,
    required this.doId,
    this.photoUrl,
  });

  factory PodUploadResponse.fromJson(Map<String, dynamic> json) {
    return PodUploadResponse(
      podId: json['pod_id'] ?? 0,
      doId: json['do_id'] ?? '',
      photoUrl: json['photo_url'],
    );
  }
}

/// Static dummy data generators for testing and documentation
class DummyJobOrders {
  /// Get dummy active orders (sedang dalam proses)
  static List<JobOrder> getActiveOrders() {
    return [
      JobOrder(
        jobOrderId: 'JO-2025-001',
        customerName: 'Kristal Anastasia',
        customerPhone: '+62 821 2344 1234',
        pickupLat: -6.2000,
        pickupLng: 106.8200,
        deliveryLat: -6.2088,
        deliveryLng: 106.8456,
        pickupAddress: 'Gudang SendPick, Jl. Industri No. 10, Jakarta Barat',
        deliveryAddress: 'Jl. Sudirman No. 123, Jakarta Pusat 10220',
        goodsDesc: 'Paket Elektronik - Laptop ASUS ROG',
        goodsWeight: 2.5,
        shipDate: '2025-12-29',
        status: 'In Transit',
        orderType: 'Express',
        assignmentStatus: 'Active',
      ),
    ];
  }

  /// Get dummy pending orders (menunggu diterima/ditolak)
  static List<JobOrder> getPendingOrders() {
    return [
      JobOrder(
        jobOrderId: 'JO-2025-002',
        customerName: 'Budi Santoso',
        customerPhone: '+62 812 3456 7890',
        pickupLat: -6.1800,
        pickupLng: 106.8100,
        deliveryLat: -6.1944,
        deliveryLng: 106.8229,
        pickupAddress: 'Kantor Notaris, Jl. Kebon Sirih No. 50, Jakarta Pusat',
        deliveryAddress: 'Jl. Thamrin No. 45, Jakarta Pusat 10350',
        goodsDesc: 'Dokumen Penting - Kontrak Kerja',
        goodsWeight: 0.5,
        shipDate: '2025-12-29',
        status: 'Processing',
        orderType: 'Same Day',
        assignmentStatus: 'Pending',
      ),
      JobOrder(
        jobOrderId: 'JO-2025-003',
        customerName: 'PT. Sendpick Indonesia',
        customerPhone: '+62 21 5555 1234',
        pickupLat: -6.2100,
        pickupLng: 106.8000,
        deliveryLat: -6.2297,
        deliveryLng: 106.8253,
        pickupAddress: 'Pabrik Mesin, Kawasan Industri Pulogadung',
        deliveryAddress: 'Jl. Gatot Subroto Kav. 78, Jakarta Selatan 12930',
        goodsDesc: 'Spare Part Mesin Industri',
        goodsWeight: 15.0,
        shipDate: '2025-12-29',
        status: 'Processing',
        orderType: 'LTL',
        assignmentStatus: 'Pending',
        specialInstruction: 'Handle with care - Heavy machinery parts',
      ),
      JobOrder(
        jobOrderId: 'JO-2025-004',
        customerName: 'Dewi Lestari',
        customerPhone: '+62 878 1234 5678',
        pickupLat: -6.2200,
        pickupLng: 106.8400,
        deliveryLat: -6.2350,
        deliveryLng: 106.8300,
        pickupAddress: 'Toko Fashion, Mall Grand Indonesia Lt. 3',
        deliveryAddress: 'Jl. Kuningan Barat No. 12, Jakarta Selatan 12710',
        goodsDesc: 'Fashion Items - Pakaian Branded',
        goodsWeight: 1.2,
        shipDate: '2025-12-29',
        status: 'Processing',
        orderType: 'Regular',
        assignmentStatus: 'Pending',
      ),
      JobOrder(
        jobOrderId: 'JO-2025-005',
        customerName: 'Restoran Nusantara',
        customerPhone: '+62 812 9876 5432',
        pickupLat: -6.2400,
        pickupLng: 106.8000,
        deliveryLat: -6.2600,
        deliveryLng: 106.8150,
        pickupAddress: 'Cold Storage Facility, Tangerang',
        deliveryAddress: 'Jl. Kemang Raya No. 88, Jakarta Selatan 12730',
        goodsDesc: 'Frozen Food - Daging Sapi Import',
        goodsWeight: 25.0,
        shipDate: '2025-12-29',
        status: 'Processing',
        orderType: 'Cold Chain',
        assignmentStatus: 'Pending',
        specialInstruction: 'Keep frozen at -18°C, deliver within 2 hours',
      ),
      JobOrder(
        jobOrderId: 'JO-2025-006',
        customerName: 'Galeri Seni Rupa',
        customerPhone: '+62 21 7654 3210',
        pickupLat: -6.1900,
        pickupLng: 106.8200,
        deliveryLat: -6.2200,
        deliveryLng: 106.8020,
        pickupAddress: 'Galeri Nasional Indonesia, Jl. Medan Merdeka',
        deliveryAddress: 'Jl. Senayan No. 15, Jakarta Selatan 12180',
        goodsDesc: 'Lukisan & Keramik Antik',
        goodsWeight: 8.5,
        shipDate: '2025-12-29',
        status: 'Processing',
        orderType: 'Fragile',
        assignmentStatus: 'Pending',
        specialInstruction: 'VERY FRAGILE - Antique items, handle with extreme care',
      ),
    ];
  }

  /// Get dummy history orders (selesai)
  static List<JobOrder> getHistoryOrders() {
    return [
      JobOrder(
        jobOrderId: 'JO-2025-H001',
        customerName: 'Siti Nurhaliza',
        customerPhone: '+62 813 5555 6666',
        pickupLat: -6.2000,
        pickupLng: 106.8200,
        deliveryLat: -6.1900,
        deliveryLng: 106.8350,
        pickupAddress: 'Toko Kosmetik, Blok M Square',
        deliveryAddress: 'Jl. Menteng Raya No. 50, Jakarta Pusat 10310',
        goodsDesc: 'Kosmetik & Skincare',
        goodsWeight: 3.0,
        shipDate: '2025-12-28',
        deliveryDate: '2025-12-28',
        status: 'Delivered',
        orderType: 'Regular',
        assignmentStatus: 'Completed',
      ),
      JobOrder(
        jobOrderId: 'JO-2025-H002',
        customerName: 'Ahmad Fauzi',
        customerPhone: '+62 858 1111 2222',
        pickupLat: -6.2500,
        pickupLng: 106.7900,
        deliveryLat: -6.2780,
        deliveryLng: 106.7850,
        pickupAddress: 'Toko Furniture, BSD City',
        deliveryAddress: 'Jl. Pondok Indah No. 200, Jakarta Selatan 12310',
        goodsDesc: 'Furniture - Meja Makan Set',
        goodsWeight: 45.0,
        shipDate: '2025-12-27',
        deliveryDate: '2025-12-27',
        status: 'Delivered',
        orderType: 'Heavy Cargo',
        assignmentStatus: 'Completed',
      ),
      JobOrder(
        jobOrderId: 'JO-2025-H003',
        customerName: 'CV. Maju Jaya',
        customerPhone: '+62 21 8888 9999',
        pickupLat: -6.2100,
        pickupLng: 106.8300,
        deliveryLat: -6.2400,
        deliveryLng: 106.8500,
        pickupAddress: 'Gudang Elektronik, Glodok',
        deliveryAddress: 'Ruko Mangga Dua, Jakarta Utara',
        goodsDesc: 'Komponen Elektronik',
        goodsWeight: 12.0,
        shipDate: '2025-12-26',
        deliveryDate: '2025-12-26',
        status: 'Delivered',
        orderType: 'Express',
        assignmentStatus: 'Completed',
      ),
    ];
  }
}

/// Job Order status enum
enum JobOrderStatus {
  processing('Processing'),
  inTransit('In Transit'),
  pickupComplete('Pickup Complete'),
  nearby('Nearby'),
  delivered('Delivered');

  final String value;
  const JobOrderStatus(this.value);

  static JobOrderStatus fromString(String status) {
    return JobOrderStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => JobOrderStatus.processing,
    );
  }
}
