import 'package:latlong2/latlong.dart';

enum OrderStatus {
  pending,
  inProgress,
  completed,
}

class Order {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final String customerName;
  final String customerPhone;
  final String namaBarang;
  final double beratKg;
  final String tipeOrderan;
  final DateTime orderDate;
  
  OrderStatus status;
  double? distanceKm;
  int? etaMinutes;
  bool isNavigating;

  Order({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.customerName,
    required this.customerPhone,
    required this.namaBarang,
    required this.beratKg,
    required this.tipeOrderan,
    required this.orderDate,
    this.status = OrderStatus.pending,
    this.distanceKm,
    this.etaMinutes,
    this.isNavigating = false,
  });

  String get formattedDistance {
    if (distanceKm == null) return '-';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get formattedEta {
    if (etaMinutes == null) return '-';
    if (etaMinutes! < 60) {
      return '$etaMinutes menit';
    } else {
      final hours = etaMinutes! ~/ 60;
      final minutes = etaMinutes! % 60;
      return '${hours}j ${minutes}m';
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.inProgress:
        return 'Sedang Dikirim';
      case OrderStatus.completed:
        return 'Selesai';
    }
  }

  String get formattedDate {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[orderDate.weekday % 7]}, ${orderDate.day} ${months[orderDate.month - 1]} ${orderDate.year}';
  }

  Order copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? position,
    String? customerName,
    String? customerPhone,
    String? namaBarang,
    double? beratKg,
    String? tipeOrderan,
    DateTime? orderDate,
    OrderStatus? status,
    double? distanceKm,
    int? etaMinutes,
    bool? isNavigating,
  }) {
    return Order(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      position: position ?? this.position,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      namaBarang: namaBarang ?? this.namaBarang,
      beratKg: beratKg ?? this.beratKg,
      tipeOrderan: tipeOrderan ?? this.tipeOrderan,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}
