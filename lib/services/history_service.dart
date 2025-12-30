import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/history_model.dart';
import 'api_client.dart';

/// Service for fetching order history and driver statistics
/// Handles /history and /history/stats endpoints
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get order history with optional date filter
  /// [startDate] defaults to 30 days ago
  /// [endDate] defaults to today
  Future<List<HistoryOrder>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (startDate != null) {
        queryParams['start_date'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = _formatDate(endDate);
      }

      final response = await _apiClient.get<List<dynamic>>(
        ApiConfig.historyEndpoint,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        fromJsonT: (data) => data as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!
            .map((e) => HistoryOrder.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal mengambil riwayat order',
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

  /// Get history for the last N days
  Future<List<HistoryOrder>> getRecentHistory({int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getHistory(startDate: startDate, endDate: endDate);
  }

  /// Get history for current month
  Future<List<HistoryOrder>> getThisMonthHistory() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    return getHistory(startDate: startDate, endDate: now);
  }

  /// Get driver statistics/KPI
  Future<HistoryStats> getStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.historyStatsEndpoint,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return HistoryStats.fromJson(response.data!);
      } else {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal mengambil statistik',
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

  /// Format date as YYYY-MM-DD for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
