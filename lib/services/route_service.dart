import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/order.dart';

class RouteResult {
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMinutes;

  RouteResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteService {
  // Multiple OSRM servers for fallback
  static const List<String> _osrmServers = [
    'https://router.project-osrm.org',
    'https://routing.openstreetmap.de/routed-car',
  ];

  /// Get route between two points using multiple OSRM servers
  /// Falls back to next server if one fails
  Future<RouteResult?> getRoute(LatLng origin, LatLng destination) async {
    // Try each OSRM server
    for (String server in _osrmServers) {
      try {
        final result = await _fetchRouteFromServer(server, origin, destination);
        if (result != null && result.polylinePoints.length > 2) {
          return result;
        }
      } catch (e) {
        print('❌ Server $server failed: $e');
        continue;
      }
    }

    // If all servers fail, use fallback
    print('⚠️ All OSRM servers failed, using fallback');
    return _calculateFallbackRoute(origin, destination);
  }

  /// Fetch route from a specific OSRM server
  Future<RouteResult?> _fetchRouteFromServer(
    String serverUrl,
    LatLng origin,
    LatLng destination,
  ) async {
    // Build URL - different servers have slightly different paths
    String url;
    if (serverUrl.contains('routing.openstreetmap.de')) {
      url = '$serverUrl/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';
    } else {
      url = '$serverUrl/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=false';
    }

    print('🚗 Trying: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'SendPickDriverApp/1.0',
      },
    ).timeout(const Duration(seconds: 10));

    print('📡 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['code'] == 'Ok' &&
          data['routes'] != null &&
          (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];

        // Distance in meters -> km
        final distanceKm = (route['distance'] as num) / 1000.0;
        // Duration in seconds -> minutes
        final durationMinutes = ((route['duration'] as num) / 60).round();

        // Parse GeoJSON coordinates
        final geometry = route['geometry'];
        if (geometry != null && geometry['coordinates'] != null) {
          final coordinates = geometry['coordinates'] as List;

          List<LatLng> points = [];
          for (var coord in coordinates) {
            // GeoJSON: [longitude, latitude]
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            points.add(LatLng(lat, lng));
          }

          print('✅ Got ${points.length} route points');

          if (points.length > 1) {
            return RouteResult(
              polylinePoints: points,
              distanceKm: distanceKm,
              durationMinutes: durationMinutes,
            );
          }
        }
      }
    }

    return null;
  }

  /// Fallback route with curved path (looks better than straight line)
  RouteResult _calculateFallbackRoute(LatLng origin, LatLng destination) {
    final distanceKm = _calculateDistance(origin, destination);
    final durationMinutes = (distanceKm * 3).round();

    // Create a curved path that follows a more realistic route pattern
    List<LatLng> points = _createRealisticPath(origin, destination);

    return RouteResult(
      polylinePoints: points,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  /// Create a path that looks more like a real road
  /// Uses bezier curve with multiple control points
  List<LatLng> _createRealisticPath(LatLng origin, LatLng destination) {
    List<LatLng> points = [];
    
    // Number of points based on distance
    final distance = _calculateDistance(origin, destination);
    int numPoints = (distance * 5).clamp(10, 50).toInt();
    
    // Calculate perpendicular offset direction
    final dx = destination.longitude - origin.longitude;
    final dy = destination.latitude - origin.latitude;
    
    // Normalized perpendicular vector
    final length = sqrt(dx * dx + dy * dy);
    final perpX = -dy / length;
    final perpY = dx / length;
    
    // Create bezier-like curve with random variations
    final random = Random(origin.latitude.hashCode);
    
    for (int i = 0; i <= numPoints; i++) {
      double t = i / numPoints;
      
      // Base interpolation
      double lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      double lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      
      // Add curve bulge in the middle (sine wave pattern)
      double bulge = sin(t * pi) * 0.003;
      
      // Add slight random variations for road-like appearance
      double noise = (random.nextDouble() - 0.5) * 0.0003;
      
      // Apply offset only in middle section
      if (i > 0 && i < numPoints) {
        lat += perpY * (bulge + noise);
        lng += perpX * (bulge + noise);
      }
      
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  /// Calculate distance using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLon = _toRadians(point2.longitude - point1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(point1.latitude)) *
            cos(_toRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Sort orders by distance from current location (nearest first)
  /// Completed orders are always at the bottom
  List<Order> sortByDistance(List<Order> orders, LatLng currentLocation) {
    final completedOrders =
        orders.where((o) => o.status == OrderStatus.completed).toList();
    final activeOrders =
        orders.where((o) => o.status != OrderStatus.completed).toList();

    for (var order in activeOrders) {
      order.distanceKm = _calculateDistance(currentLocation, order.position);
      order.etaMinutes = (order.distanceKm! * 3).round();
    }

    activeOrders.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    return [...activeOrders, ...completedOrders];
  }

  /// Get dummy orders for testing and documentation
  static List<Order> getDummyOrders() {
    return [
      // Active order - sedang dikirim
      Order(
        id: 'JO-2025-001',
        name: 'Pengantaran ke Kristal Anastasia',
        address: 'Jl. Sudirman No. 123, Jakarta Pusat 10220',
        position: const LatLng(-6.2088, 106.8456),
        customerName: 'Kristal Anastasia',
        customerPhone: '+62 821 2344 1234',
        namaBarang: 'Paket Elektronik - Laptop ASUS',
        beratKg: 2.5,
        tipeOrderan: 'Express Delivery',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.inProgress,
      ),
      // Pending order - menunggu pickup
      Order(
        id: 'JO-2025-002',
        name: 'Pengantaran ke Budi Santoso',
        address: 'Jl. Thamrin No. 45, Jakarta Pusat 10350',
        position: const LatLng(-6.1944, 106.8229),
        customerName: 'Budi Santoso',
        customerPhone: '+62 812 3456 7890',
        namaBarang: 'Dokumen Penting - Kontrak Kerja',
        beratKg: 0.5,
        tipeOrderan: 'Same Day',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.pending,
      ),
      // Pending order - barang berat
      Order(
        id: 'JO-2025-003',
        name: 'Pengantaran ke PT. Sendpick Indonesia',
        address: 'Jl. Gatot Subroto Kav. 78, Jakarta Selatan 12930',
        position: const LatLng(-6.2297, 106.8253),
        customerName: 'PT. Sendpick Indonesia',
        customerPhone: '+62 21 5555 1234',
        namaBarang: 'Spare Part Mesin Industri',
        beratKg: 15.0,
        tipeOrderan: 'LTL Delivery',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.pending,
      ),
      // Pending order - fashion
      Order(
        id: 'JO-2025-004',
        name: 'Pengantaran ke Dewi Lestari',
        address: 'Jl. Kuningan Barat No. 12, Jakarta Selatan 12710',
        position: const LatLng(-6.2350, 106.8300),
        customerName: 'Dewi Lestari',
        customerPhone: '+62 878 1234 5678',
        namaBarang: 'Fashion Items - Pakaian Branded',
        beratKg: 1.2,
        tipeOrderan: 'Regular',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.pending,
      ),
      // Pending order - makanan/frozen
      Order(
        id: 'JO-2025-005',
        name: 'Pengantaran ke Restoran Nusantara',
        address: 'Jl. Kemang Raya No. 88, Jakarta Selatan 12730',
        position: const LatLng(-6.2600, 106.8150),
        customerName: 'Restoran Nusantara',
        customerPhone: '+62 812 9876 5432',
        namaBarang: 'Frozen Food - Daging Sapi Import',
        beratKg: 25.0,
        tipeOrderan: 'Cold Chain',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.pending,
      ),
      // Pending order - fragile
      Order(
        id: 'JO-2025-006',
        name: 'Pengantaran ke Galeri Seni Rupa',
        address: 'Jl. Senayan No. 15, Jakarta Selatan 12180',
        position: const LatLng(-6.2200, 106.8020),
        customerName: 'Galeri Seni Rupa',
        customerPhone: '+62 21 7654 3210',
        namaBarang: 'Lukisan & Keramik Antik',
        beratKg: 8.5,
        tipeOrderan: 'Fragile Handling',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.pending,
      ),
      // Pending order - furniture
      Order(
        id: 'JO-2025-007',
        name: 'Pengantaran ke Ahmad Fauzi',
        address: 'Jl. Pondok Indah No. 200, Jakarta Selatan 12310',
        position: const LatLng(-6.2780, 106.7850),
        customerName: 'Ahmad Fauzi',
        customerPhone: '+62 858 1111 2222',
        namaBarang: 'Furniture - Meja Makan Set',
        beratKg: 45.0,
        tipeOrderan: 'Heavy Cargo',
        orderDate: DateTime(2025, 12, 29),
        status: OrderStatus.pending,
      ),
      // Completed order
      Order(
        id: 'JO-2025-008',
        name: 'Pengantaran ke Siti Nurhaliza',
        address: 'Jl. Menteng Raya No. 50, Jakarta Pusat 10310',
        position: const LatLng(-6.1900, 106.8350),
        customerName: 'Siti Nurhaliza',
        customerPhone: '+62 813 5555 6666',
        namaBarang: 'Kosmetik & Skincare',
        beratKg: 3.0,
        tipeOrderan: 'Regular',
        orderDate: DateTime(2025, 12, 28),
        status: OrderStatus.completed,
      ),
    ];
  }
}
