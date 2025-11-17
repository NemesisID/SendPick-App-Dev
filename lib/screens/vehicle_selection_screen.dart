import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';
import '../main.dart'; // Import main to access authService

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  List<Vehicle> _availableVehicles = [];
  bool _isLoading = true;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadAvailableVehicles();
  }

  Future<void> _loadAvailableVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await VehicleService.fetchAvailableVehicles();
      setState(() {
        _availableVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load available vehicles. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectVehicle(String vehicleId) async {
    setState(() {
      _selectedVehicleId = vehicleId;
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedVehicleId == null) {
      _showErrorDialog('Please select a vehicle first.');
      return;
    }

    try {
      // Get current driver ID from auth service
      final driverId = authService.currentUserId;
      if (driverId == null) {
        _showErrorDialog('Authentication error. Please login again.');
        return;
      }

      // Assign the vehicle to the driver
      final success = await VehicleService.assignVehicleToDriver(
        _selectedVehicleId!, 
        driverId,
      );

      if (success) {
        // Update the auth service with the selected vehicle
        authService.setSelectedVehicle(_selectedVehicleId!);
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorDialog('Failed to select vehicle. Please try again.');
        setState(() {
          _selectedVehicleId = null;
        });
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
      setState(() {
        _selectedVehicleId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Your Vehicle',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Remove leading back button to prevent users from going back without selecting a vehicle
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a vehicle for your delivery',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_availableVehicles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No vehicles available',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please try again later',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _availableVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _availableVehicles[index];
                    final isSelected = _selectedVehicleId == vehicle.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected 
                            ? Colors.blue.shade600 
                            : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? Colors.blue.shade50 
                              : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected 
                                ? Colors.blue.shade600 
                                : Colors.grey.shade300,
                            ),
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            color: isSelected 
                              ? Colors.blue.shade600 
                              : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          vehicle.plateNumber,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                              ? Colors.blue.shade600 
                              : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${vehicle.brand} ${vehicle.model}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Text(
                                'Available',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.blue.shade600,
                                size: 30,
                              )
                            : null,
                        onTap: () {
                          _selectVehicle(vehicle.id);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedVehicleId != null ? _confirmSelection : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedVehicleId != null 
                ? Colors.blue.shade600 
                : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Select Vehicle',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}