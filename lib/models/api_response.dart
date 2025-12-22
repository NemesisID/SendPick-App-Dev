/// Standard API Response wrapper for SendPick API
/// 
/// All API responses follow the format:
/// ```json
/// {
///   "success": true/false,
///   "message": "...",
///   "data": {...} or [...]
/// }
/// ```
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }

  /// Check if response is successful
  bool get isSuccess => success;

  /// Check if response has error
  bool get isError => !success;

  /// Get error message or default
  String get errorMessage => message ?? 'Terjadi kesalahan';
}

/// API Error class for structured error handling
class ApiError implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiError({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'ApiError($statusCode): $message';

  /// Check if error is authentication related
  bool get isAuthError => statusCode == 401;

  /// Check if error is forbidden
  bool get isForbidden => statusCode == 403;

  /// Check if error is not found
  bool get isNotFound => statusCode == 404;

  /// Check if error is validation error
  bool get isValidationError => statusCode == 422;

  /// Check if error is server error
  bool get isServerError => statusCode >= 500;
}
