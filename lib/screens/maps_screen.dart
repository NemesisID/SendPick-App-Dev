import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/map_helper.dart';
import '../models/order.dart';
import '../models/api_response.dart';
import '../services/route_service.dart';
import '../services/gps_service.dart';
import '../services/job_service.dart';
import '../main.dart';
import 'scan_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();
  final GpsService _gpsService = GpsService();
  final JobService _jobService = JobService();
  
  LatLng _currentPosition = const LatLng(-6.2088, 106.8456);
  bool _isLoading = true;
  String? _errorMessage;
  
  List<Order> _orders = [];
  Order? _navigatingOrder;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _isOffline = false;
  int _currentTileServer = 0;

  // Navigation mode state
  double _currentHeading = 0.0;
  StreamSubscription<Position>? _positionStream;
  bool _followUser = false;
  bool _hideNavInfo = false; // Hide/show navigation info card

  // Multiple tile servers for fallback
  static const List<String> _tileServers = [
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
    'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkConnectivity();
    await _getCurrentLocation();
    await _loadOrders();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });

      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((result) {
        if (mounted) {
          setState(() {
            _isOffline = result == ConnectivityResult.none;
          });
        }
      });
    } catch (e) {
      print('Connectivity check error: $e');
    }
  }

  /// Load orders from API
  Future<void> _loadOrders() async {
    setState(() {
      _errorMessage = null;
    });

    // === DUMMY ORDER FOR TESTING NAVIGATION ===
    // Lokasi: Tugu Pahlawan Surabaya
    final dummyOrder = Order(
      id: 'JO-TEST-001',
      name: 'Test Navigasi - Tugu Pahlawan Surabaya',
      address: 'Jl. Pahlawan, Alun-alun Contong, Bubutan, Surabaya 60174',
      position: const LatLng(-7.2458, 112.7378), // Koordinat Tugu Pahlawan
      customerName: 'Test Customer',
      customerPhone: '+62 812 0000 0000',
      namaBarang: 'Paket Test',
      beratKg: 1.0,
      tipeOrderan: 'Express',
      orderDate: DateTime.now(),
      status: OrderStatus.inProgress,
    );

    // Langsung set dummy order tanpa tunggu API
    _orders = [dummyOrder];
    if (mounted) setState(() {});
    // === END DUMMY ===

    // Juga coba load dari API (opsional, bisa di-comment jika tidak perlu)
    try {
      final response = await _jobService.getJobs();

      // Convert JobOrder to Order for maps
      final List<Order> orders = [dummyOrder]; // Tetap sertakan dummy

      // Add active orders
      for (final jobOrder in response.activeOrders) {
        orders.add(Order.fromJobOrder(jobOrder));
      }

      // Add pending orders (optional - you might want to show only active)
      for (final jobOrder in response.pendingOrders) {
        orders.add(Order.fromJobOrder(jobOrder));
      }

      // Sort by distance from current location
      _orders = _routeService.sortByDistance(orders, _currentPosition);

      if (mounted) setState(() {});
    } on ApiError catch (e) {
      // Jika API gagal, tetap gunakan dummy order
      print('API Error (using dummy): ${e.message}');
    } catch (e) {
      // Jika error lain, tetap gunakan dummy order
      print('Error loading orders (using dummy): $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        _showPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Wait for map to be ready before moving
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentPosition, 14);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error getting location: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Lokasi Diperlukan'),
        content: const Text(
          'Aplikasi membutuhkan akses lokasi untuk menampilkan posisi Anda di peta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  Future<void> _startNavigation(Order order) async {
    setState(() {
      _isLoadingRoute = true;
      _navigatingOrder = order;
      _followUser = true;

      // Update order status
      for (var o in _orders) {
        o.isNavigating = o.id == order.id;
      }
    });

    // Zoom in to user location with navigation view
    _mapController.move(_currentPosition, 17);

    // Start location stream for real-time heading updates
    _startLocationStream();

    // Fetch route from OSRM
    final result = await _routeService.getRoute(
      _currentPosition,
      order.position,
    );

    if (result != null && mounted) {
      setState(() {
        _routePoints = result.polylinePoints;
        _isLoadingRoute = false;

        // Update order with accurate distance/ETA
        order.distanceKm = result.distanceKm;
        order.etaMinutes = result.durationMinutes;
      });
    } else {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _startLocationStream() {
    _positionStream?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted && _navigatingOrder != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentHeading = position.heading;
        });

        // Add location to GPS buffer for API tracking
        _gpsService.addLocation(
          position.latitude,
          position.longitude,
          orderId: _navigatingOrder?.id,
          vehicleId: authService.selectedVehicleId,
        );

        // Follow user if enabled
        if (_followUser) {
          _mapController.move(_currentPosition, _mapController.camera.zoom);
        }
      }
    });
    
    // Start GPS tracking service (sends data every 30 seconds)
    _gpsService.startTracking(
      orderId: _navigatingOrder?.id,
      vehicleId: authService.selectedVehicleId,
    );
  }

  Future<void> _stopLocationStream() async {
    _positionStream?.cancel();
    _positionStream = null;
    
    // Stop GPS tracking and flush remaining buffer
    await _gpsService.stopTracking();
  }

  Future<void> _stopNavigation() async {
    // Stop location stream and GPS tracking
    await _stopLocationStream();

    setState(() {
      _navigatingOrder = null;
      _routePoints = [];
      _followUser = false;
      _currentHeading = 0.0;

      for (var o in _orders) {
        o.isNavigating = false;
      }
    });

    _mapController.move(_currentPosition, 14);
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    double minLat = _currentPosition.latitude;
    double maxLat = _currentPosition.latitude;
    double minLng = _currentPosition.longitude;
    double maxLng = _currentPosition.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void _onOrderCompleted(String orderId) {
    setState(() {
      for (var order in _orders) {
        if (order.id == orderId) {
          order.status = OrderStatus.completed;
          order.isNavigating = false;
        }
      }

      _navigatingOrder = null;
      _routePoints = [];

      // Re-sort orders (completed go to bottom)
      _orders = _routeService.sortByDistance(_orders, _currentPosition);
    });
  }

  void _moveToLocation(LatLng position) {
    _mapController.move(position, 16);
  }

  void _recenterToCurrentLocation() {
    _mapController.move(_currentPosition, 14);
  }

  /// Build navigation arrow that rotates based on heading
  Widget _buildNavigationArrow() {
    return Transform.rotate(
      angle: _currentHeading * (math.pi / 180), // Convert degrees to radians
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF021E7B),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 28),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Current location marker - arrow when navigating, car when not
    markers.add(
      Marker(
        point: _currentPosition,
        width: 50,
        height: 50,
        child:
            _navigatingOrder != null
                ? _buildNavigationArrow()
                : MapHelper.createCarMarker(),
      ),
    );

    // Destination markers
    for (int i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      markers.add(
        Marker(
          point: order.position,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(i),
            child: MapHelper.createDestinationMarker(
              index: i,
              isActive: order.isNavigating,
              isCompleted: order.status == OrderStatus.completed,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _onMarkerTapped(int index) {
    // Marker tapped - no scroll animation needed
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Flutter Map
        _isLoading
            ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF021E7B)),
            )
            : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 14,
                onTap: (tapPosition, point) {
                  // Map tapped - no scroll animation needed
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileServers[_currentTileServer],
                  userAgentPackageName: 'com.example.sendpick_app',
                  errorTileCallback: (tile, error, stackTrace) {
                    // Try next tile server on error
                    if (_currentTileServer < _tileServers.length - 1) {
                      setState(() {
                        _currentTileServer++;
                      });
                    }
                  },
                ),
                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        color: MapHelper.activeRouteColor,
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),

        // Offline Banner
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mode Offline - Peta mungkin tidak tersedia',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Navigation Mode Overlay
        if (_navigatingOrder != null) _buildNavigationOverlay(),

        // Draggable Bottom Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.15,
          minChildSize: 0.15,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle bar tapped - sheet will expand/collapse naturally
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lokasi Pengantaran',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sort,
                                        size: 14,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Terdekat',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF021E7B,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_orders.where((o) => o.status != OrderStatus.completed).length} Aktif',
                                    style: const TextStyle(
                                      color: Color(0xFF021E7B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._orders.asMap().entries.map((entry) {
                          return _buildDeliveryCard(entry.value, entry.key);
                        }),
                        const SizedBox(
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Button kembali ke lokasi saat ini (selalu tampil)
        Positioned(
          bottom: _navigatingOrder != null ? 120 : 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'recenter',
            onPressed: _recenterToCurrentLocation,
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.my_location, color: Color(0xFF021E7B)),
          ),
        ),

        // Loading overlay for route calculation
        if (_isLoadingRoute)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF021E7B)),
                      SizedBox(height: 16),
                      Text('Menghitung rute...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationOverlay() {
    final order = _navigatingOrder!;

    // If hidden, show minimal bar with toggle button
    if (_hideNavInfo) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF021E7B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  order.formattedDistance,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.expand_more, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _hideNavInfo = false),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full navigation overlay
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF021E7B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menuju Lokasi',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          order.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hide button
                  IconButton(
                    icon: const Icon(Icons.expand_less, color: Colors.white),
                    tooltip: 'Sembunyikan',
                    onPressed: () => setState(() => _hideNavInfo = true),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _stopNavigation,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.address,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              // Info chips row
              Row(
                children: [
                  _buildInfoChip(Icons.route, order.formattedDistance),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.access_time, order.formattedEta),
                ],
              ),
              const SizedBox(height: 12),
              // Button row
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ScanScreen(
                              onBackTap: () => Navigator.pop(context),
                              currentOrder: _navigatingOrder,
                              availableOrders:
                                  _orders
                                      .where(
                                        (o) =>
                                            o.status != OrderStatus.completed,
                                      )
                                      .toList(),
                              onOrderCompleted: _onOrderCompleted,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Order order, int index) {
    final bool isActive = order.status == OrderStatus.inProgress;
    final bool isCompleted = order.status == OrderStatus.completed;
    final bool isNavigating = order.isNavigating;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isNavigating ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isNavigating
                ? const BorderSide(color: Color(0xFF021E7B), width: 2)
                : isActive
                ? BorderSide(color: Colors.green.shade300, width: 2)
                : BorderSide.none,
      ),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: InkWell(
          onTap:
              isCompleted
                  ? null
                  : () {
                    _moveToLocation(order.position);
                  },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Colors.grey.shade100
                                : isNavigating
                                ? const Color(0xFF021E7B).withOpacity(0.1)
                                : isActive
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child:
                            isCompleted
                                ? Icon(Icons.check, color: Colors.grey[600])
                                : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isNavigating
                                            ? const Color(0xFF021E7B)
                                            : isActive
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                order.id,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Colors.grey
                                : isNavigating
                                ? const Color(0xFF021E7B)
                                : isActive
                                ? Colors.green
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isNavigating ? 'Navigasi Aktif' : order.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.route, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          order.formattedDistance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.formattedEta,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child:
                        isNavigating
                            ? OutlinedButton.icon(
                              onPressed: _stopNavigation,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Batal Navigasi'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                            : ElevatedButton.icon(
                              onPressed: () => _startNavigation(order),
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text('Navigasi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF021E7B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}