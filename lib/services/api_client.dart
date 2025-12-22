import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';

/// HTTP Client wrapper for SendPick API
/// Handles authentication, token management, and error handling
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _driverDataKey = 'driver_data';

  /// Get stored auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Store auth token securely
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Clear auth token (logout)
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// Store driver data as JSON
  Future<void> setDriverData(Map<String, dynamic> driverData) async {
    await _secureStorage.write(
      key: _driverDataKey,
      value: jsonEncode(driverData),
    );
  }

  /// Get stored driver data
  Future<Map<String, dynamic>?> getDriverData() async {
    final data = await _secureStorage.read(key: _driverDataKey);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Build headers for API requests
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Build full URL for endpoint
  String _buildUrl(String endpoint) {
    return '${ApiConfig.driverApiUrl}$endpoint';
  }

  /// Handle HTTP response and convert to ApiResponse
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    final statusCode = response.statusCode;
    
    try {
      final body = jsonDecode(response.body);
      
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.fromJson(body, fromJsonT);
      } else {
        throw ApiError(
          statusCode: statusCode,
          message: body['message'] ?? 'Terjadi kesalahan',
          data: body['data'],
        );
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      
      throw ApiError(
        statusCode: statusCode,
        message: 'Gagal memproses response: ${e.toString()}',
      );
    }
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      var url = Uri.parse(_buildUrl(endpoint));
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }

      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiError(
        statusCode: 0,
        message: 'Tidak ada koneksi internet',
      );
    } on http.ClientException catch (e) {
      throw ApiError(
        statusCode: 0,
        message: 'Gagal terhubung ke server: ${e.message}',
      );
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiError(
        statusCode: 0,
        message: 'Tidak ada koneksi internet',
      );
    } on http.ClientException catch (e) {
      throw ApiError(
        statusCode: 0,
        message: 'Gagal terhubung ke server: ${e.message}',
      );
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiError(
        statusCode: 0,
        message: 'Tidak ada koneksi internet',
      );
    } on http.ClientException catch (e) {
      throw ApiError(
        statusCode: 0,
        message: 'Gagal terhubung ke server: ${e.message}',
      );
    }
  }

  /// POST multipart request (for file uploads)
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, File>? files,
    bool requiresAuth = true,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final request = http.MultipartRequest('POST', url);

      // Add auth header
      if (requiresAuth) {
        final token = await getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      // Add fields
      request.fields.addAll(fields);

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiError(
        statusCode: 0,
        message: 'Tidak ada koneksi internet',
      );
    } on http.ClientException catch (e) {
      throw ApiError(
        statusCode: 0,
        message: 'Gagal terhubung ke server: ${e.message}',
      );
    }
  }
}
