import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/driver_model.dart';
import 'api_client.dart';

/// Authentication service for SendPick Driver App
/// Handles login, logout, and driver session management
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  // Cached driver data
  Driver? _currentDriver;
  String? _selectedVehicleId;

  /// Get current logged in driver
  Driver? get currentDriver => _currentDriver;

  /// Get current user ID (for backward compatibility)
  String? get currentUserId => _currentDriver?.driverId;

  /// Get selected vehicle ID
  String? get selectedVehicleId => _selectedVehicleId;

  /// Check if user is logged in (has valid token)
  Future<bool> get isLoggedIn async => await _apiClient.isAuthenticated();

  /// Synchronous check for navigation (uses cached state)
  bool get isLoggedInSync => _currentDriver != null;

  /// Login with email and password
  ///
  /// Returns [LoginResponse] on success, throws [ApiError] on failure
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.loginEndpoint,
        body: {'email': email, 'password': password},
        requiresAuth: false,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final loginResponse = LoginResponse.fromJson(response.data!);
        
        // Store token
        await _apiClient.setToken(loginResponse.token);

        // Store driver data
        await _apiClient.setDriverData(loginResponse.driver.toJson());

        // Cache driver
        _currentDriver = loginResponse.driver;
        
        return loginResponse;
      } else {
        throw ApiError(
          statusCode: 401,
          message: response.message ?? 'Login gagal',
        );
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        statusCode: 0,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Logout current driver
  Future<void> logout() async {
    try {
      // Call logout API (best effort, don't fail if offline)
      await _apiClient.post(ApiConfig.logoutEndpoint, requiresAuth: true);
    } catch (e) {
      // Ignore errors, proceed with local logout
    } finally {
      // Clear all local data
      await _apiClient.clearAll();
      _currentDriver = null;
      _selectedVehicleId = null;
    }
  }

  /// Initialize service - load cached driver data
  Future<void> initialize() async {
    if (await _apiClient.isAuthenticated()) {
      final driverData = await _apiClient.getDriverData();
      if (driverData != null) {
        _currentDriver = Driver.fromJson(driverData);
      }
    }
  }

  /// Get current driver profile from API
  Future<Driver> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConfig.profileEndpoint,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final driver = Driver.fromJson(response.data!);
      _currentDriver = driver;
      await _apiClient.setDriverData(driver.toJson());
      return driver;
    } else {
      throw ApiError(
        statusCode: 404,
        message: response.message ?? 'Gagal mengambil profil',
      );
    }
  }

  /// Update driver status (Available, On Duty, Off Duty)
  Future<void> updateStatus(DriverStatus status) async {
    final response = await _apiClient.put(
      ApiConfig.statusEndpoint,
      body: {'status': status.value},
    );

    if (response.isSuccess) {
      // Update cached driver status
      if (_currentDriver != null) {
        _currentDriver = _currentDriver!.copyWith(status: status.value);
        await _apiClient.setDriverData(_currentDriver!.toJson());
      }
    } else {
      throw ApiError(
        statusCode: 400,
        message: response.message ?? 'Gagal mengubah status',
      );
    }
  }

  /// Set selected vehicle for current session
  void setSelectedVehicle(String vehicleId) {
    _selectedVehicleId = vehicleId;
  }

  /// Clear selected vehicle
  void clearSelectedVehicle() {
    _selectedVehicleId = null;
  }

  /// Check if user has selected a vehicle
  bool get hasSelectedVehicle => _selectedVehicleId != null;
}