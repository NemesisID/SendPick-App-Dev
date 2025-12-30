/// API Configuration for SendPick Driver App
class ApiConfig {
  /// Base URL for the SendPick API
  static const String baseUrl = 'https://sendpick.isslab.web.id';
  
  /// API path prefix for driver endpoints
  static const String apiPath = '/api/driver';
  
  /// Full base URL for driver API
  static String get driverApiUrl => '$baseUrl$apiPath';
  
  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  /// Maximum file size for uploads (5MB)
  static const int maxUploadSizeBytes = 5 * 1024 * 1024;
  
  // === ENDPOINTS ===
  
  /// Authentication
  static const String loginEndpoint = '/login';
  static const String logoutEndpoint = '/logout';
  
  /// Profile & Status
  static const String profileEndpoint = '/profile';
  static const String statusEndpoint = '/status';
  
  /// Jobs
  static const String jobsEndpoint = '/jobs';
  static String jobDetailEndpoint(String jobId) => '/jobs/$jobId';
  static String acceptJobEndpoint(String jobId) => '/jobs/$jobId/accept';
  static String rejectJobEndpoint(String jobId) => '/jobs/$jobId/reject';
  static String updateJobStatusEndpoint(String jobId) => '/jobs/$jobId/status';
  static String uploadPodEndpoint(String jobId) => '/jobs/$jobId/pod';
  
  /// FCM Token (Push Notification)
  static const String fcmTokenEndpoint = '/fcm-token';
  
  /// QR & GPS
  static const String scanQrEndpoint = '/scan-qr';
  static const String gpsBulkEndpoint = '/gps/bulk';
  
  /// History
  static const String historyEndpoint = '/history';
  static const String historyStatsEndpoint = '/history/stats';
  
  /// Vehicles
  static String vehicleCheckEndpoint(String vehicleId) =>
      '/vehicles/$vehicleId/check';
}
