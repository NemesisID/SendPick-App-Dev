import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/map_helper.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-6.2088, 106.8456); // Default Jakarta
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final DraggableScrollableController _scrollController =
      DraggableScrollableController();

  // Daftar lokasi tujuan pengantaran
  final List<Map<String, dynamic>> _deliveryLocations = [
    {
      'name': 'Lokasi Pengantaran 1',
      'address': 'Jl. Sudirman No. 123, Jakarta Pusat',
      'position': const LatLng(-6.2088, 106.8456),
      'status': 'Sedang Dikirim',
      'distance': '2.5 km',
      'eta': '15 menit',
    },
    {
      'name': 'Lokasi Pengantaran 2',
      'address': 'Jl. Thamrin No. 45, Jakarta Pusat',
      'position': const LatLng(-6.1944, 106.8229),
      'status': 'Menunggu',
      'distance': '5.8 km',
      'eta': '25 menit',
    },
    {
      'name': 'Lokasi Pengantaran 3',
      'address': 'Jl. Gatot Subroto No. 78, Jakarta Selatan',
      'position': const LatLng(-6.2297, 106.8253),
      'status': 'Menunggu',
      'distance': '8.2 km',
      'eta': '35 menit',
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14),
      );

      await _loadMarkers();
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error getting location: $e');
    }
  }

  Future<void> _loadMarkers() async {
    Set<Marker> markers = {};

    // Marker untuk lokasi saat ini (Truk - Biru)
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        icon: MapHelper.createColoredMarker(Colors.blue),
        infoWindow: const InfoWindow(
          title: 'Lokasi Anda',
          snippet: 'Posisi driver saat ini',
        ),
        anchor: const Offset(0.5, 0.5),
      ),
    );

    // Markers untuk lokasi tujuan
    for (int i = 0; i < _deliveryLocations.length; i++) {
      final location = _deliveryLocations[i];
      markers.add(
        Marker(
          markerId: MarkerId('destination_$i'),
          position: location['position'],
          icon: MapHelper.createColoredMarker(
            location['status'] == 'Sedang Dikirim'
                ? Colors.green
                : Colors.orange,
          ),
          infoWindow: InfoWindow(
            title: location['name'],
            snippet: '${location['distance']} • ${location['eta']}',
          ),
          onTap: () => _onMarkerTapped(i),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _onMarkerTapped(int index) {
    _scrollController.animateTo(
      0.4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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

  void _moveToLocation(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
  }

  void _recenterToCurrentLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                )
              : GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: true, // Menampilkan traffic
                  buildingsEnabled: true,
                  mapType: MapType.normal,
                  onTap: (position) {
                    // Minimize bottom sheet saat tap map
                    if (_scrollController.size > 0.2) {
                      _scrollController.animateTo(
                        0.15,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            controller: _scrollController,
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
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
                    // Scroll Indicator
                    GestureDetector(
                      onTap: () {
                        if (_scrollController.size < 0.5) {
                          _scrollController.animateTo(
                            0.7,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } else {
                          _scrollController.animateTo(
                            0.15,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
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

                    // Content
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_deliveryLocations.length} Lokasi',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // List lokasi pengantaran
                          ..._deliveryLocations.map((location) {
                            return _buildDeliveryCard(location);
                          }).toList(),

                          const SizedBox(height: 80), // Padding bottom
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Button kembali ke lokasi saat ini
          Positioned(
            bottom: 250,
            right: 16,
            child: FloatingActionButton(
              onPressed: _recenterToCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> location) {
    final bool isActive = location['status'] == 'Sedang Dikirim';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          _moveToLocation(location['position']);
          _scrollController.animateTo(
            0.15,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: isActive ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location['address'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),

              const SizedBox(height: 12),

              // Status & Info Row
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      location['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Distance & ETA
                  Row(
                    children: [
                      Icon(Icons.route, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        location['distance'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        location['eta'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}