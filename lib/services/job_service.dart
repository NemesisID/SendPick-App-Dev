import 'dart:io';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/job_order_model.dart';
import 'api_client.dart';

/// Service for managing job orders
/// Handles all job-related API operations
class JobService {
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get all jobs (active and pending orders)
  /// Returns [JobsResponse] containing active_orders and pending_orders
  Future<JobsResponse> getJobs() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.jobsEndpoint,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return JobsResponse.fromJson(response.data!);
      } else {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal mengambil daftar order',
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

  /// Get job detail by ID
  /// Returns [JobOrder] with full order details including assignment and delivery order
  Future<JobOrder> getJobDetail(String jobOrderId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.jobDetailEndpoint(jobOrderId),
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // API returns data wrapped in 'job_order' key
        final jobData = response.data!['job_order'] ?? response.data!;
        return JobOrder.fromJson(jobData);
      } else {
        throw ApiError(
          statusCode: 404,
          message: response.message ?? 'Job order tidak ditemukan',
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

  /// Accept a pending order
  /// [vehicleId] is optional - can be filled later
  Future<AcceptOrderResponse> acceptOrder(String jobOrderId, {String? vehicleId}) async {
    try {
      final body = <String, dynamic>{};
      if (vehicleId != null) {
        body['vehicle_id'] = vehicleId;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.acceptJobEndpoint(jobOrderId),
        body: body.isNotEmpty ? body : null,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AcceptOrderResponse.fromJson(response.data!);
      } else {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal menerima order',
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

  /// Reject a pending order
  /// [reason] is optional - can provide explanation for rejection
  Future<void> rejectOrder(String jobOrderId, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await _apiClient.post(
        ApiConfig.rejectJobEndpoint(jobOrderId),
        body: body.isNotEmpty ? body : null,
      );

      if (!response.isSuccess) {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal menolak order',
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

  /// Update job status
  /// [status] values: Processing, In Transit, Pickup Complete, Nearby, Delivered
  /// [notes] is optional additional notes
  Future<void> updateJobStatus(String jobOrderId, String status, {String? notes}) async {
    try {
      final body = <String, dynamic>{
        'status': status,
      };
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _apiClient.put(
        ApiConfig.updateJobStatusEndpoint(jobOrderId),
        body: body,
      );

      if (!response.isSuccess) {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal mengubah status order',
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

  /// Update job status using enum
  Future<void> updateJobStatusEnum(String jobOrderId, JobOrderStatus status, {String? notes}) async {
    return updateJobStatus(jobOrderId, status.value, notes: notes);
  }

  /// Upload Proof of Delivery
  /// [recipientName] is required
  /// [photo] is optional photo file (jpg, jpeg, png, max 5MB)
  /// [notes] is optional additional notes
  Future<PodUploadResponse> uploadProofOfDelivery(
    String jobOrderId, {
    required String recipientName,
    File? photo,
    String? notes,
  }) async {
    try {
      final fields = <String, String>{
        'recipient_name': recipientName,
      };
      if (notes != null && notes.isNotEmpty) {
        fields['notes'] = notes;
      }

      final files = <String, File>{};
      if (photo != null) {
        files['photo'] = photo;
      }

      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        ApiConfig.uploadPodEndpoint(jobOrderId),
        fields: fields,
        files: files.isNotEmpty ? files : null,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return PodUploadResponse.fromJson(response.data!);
      } else {
        throw ApiError(
          statusCode: 400,
          message: response.message ?? 'Gagal upload bukti pengiriman',
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
}
