import 'dart:math';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mock user data - in a real app, this would come from authentication
  String? _currentUserId;
  String? _selectedVehicleId;

  String? get currentUserId => _currentUserId;
  String? get selectedVehicleId => _selectedVehicleId;

  bool get isLoggedIn => _currentUserId != null;

  // Simulate login
  Future<bool> login(String email, String password) async {
    // In a real app, you would validate credentials with a backend
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    // For demo purposes, we'll set a mock user ID
    _currentUserId = 'driver_${Random().nextInt(1000)}';
    return true;
  }

  // Simulate logout
  Future<void> logout() async {
    _currentUserId = null;
    _selectedVehicleId = null;
  }

  // Set selected vehicle
  void setSelectedVehicle(String vehicleId) {
    _selectedVehicleId = vehicleId;
  }

  // Clear selected vehicle when ending a trip
  void clearSelectedVehicle() {
    _selectedVehicleId = null;
  }

  // Check if user has selected a vehicle
  bool get hasSelectedVehicle => _selectedVehicleId != null;
}