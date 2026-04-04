import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/kyc_document.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(ApiClient());
});

class KycRepository {
  final ApiClient _api;

  KycRepository(this._api);

  /// List all users with pending KYC verification.
  Future<Map<String, dynamic>> getPendingKycQueue({
    int page = 1,
    int size = 10,
    String? userType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (userType != null) queryParams['user_type'] = userType;

      final response = await _api.get('/api/v1/admin/kyc/pending', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      print("Error fetching pending KYC queue: $e");
      return {'items': [], 'total': 0, 'page': page, 'size': size};
    }
  }

  /// List all KYC documents with user info.
  Future<Map<String, dynamic>> getDocuments({
    int skip = 0,
    int limit = 50,
    String? status,
    String? search,
  }) async {
    final docs = await listKycDocuments(skip: skip, limit: limit, status: status, search: search);
    return {
      'documents': docs,
      'total_count': docs.length,
    };
  }

  Future<List<KycDocument>> listKycDocuments({
    int skip = 0,
    int limit = 50,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _api.get('/api/v1/admin/kyc-docs/', queryParameters: queryParams);
      
      List data;
      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map && response.data['items'] is List) {
        data = response.data['items'];
      } else {
        data = [];
      }
      
      return data.map((json) => KycDocument.fromJson(json)).toList();
    } catch (e) {
      print("Error listing KYC documents: $e");
      return [];
    }
  }

  /// Get global KYC stats
  Future<KYCStats> getStats() async {
    final data = await getKycStats();
    return KYCStats.fromJson(data);
  }

  Future<Map<String, dynamic>> getKycStats() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc-docs/stats');
      return response.data;
    } catch (e) {
      print("Error fetching KYC stats: $e");
      return {};
    }
  }

  /// Get a single KYC document with user details
  Future<KycDocument?> getDocumentDetail(int docId) async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/documents/$docId');
      return KycDocument.fromJson(response.data);
    } catch (e) {
      print("Error fetching document detail for $docId: $e");
      return null;
    }
  }

  /// Approve individual document (POST)
  Future<bool> approveDocument(int docId) async {
    try {
      await _api.post('/api/v1/admin/kyc/documents/$docId/approve');
      return true;
    } catch (e) {
      print('Error approving document $docId: $e');
      return false;
    }
  }

  /// Reject individual document with reason (POST)
  Future<bool> rejectDocument(int docId, String reason) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/documents/$docId/reject',
        data: {'reason': reason},
      );
      return true;
    } catch (e) {
      print('Error rejecting document $docId: $e');
      return false;
    }
  }

  /// Finalize KYC decision (Approve or Reject entire submission)
  Future<void> verifyKycSubmission(
    int userId, {
    required String decision,
    String? notes,
    Map<String, dynamic>? rejectionReasons,
  }) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/$userId/verify',
        data: {
          'decision': decision,
          'notes': notes,
          'rejection_reasons': rejectionReasons ?? {},
        },
      );
    } catch (e) {
      throw Exception('Failed to finalize KYC: $e');
    }
  }

  /// Reject submission with a mandatory reason (POST)
  Future<void> rejectSubmission(int userId, String reason, {Map<String, dynamic>? rejectionReasons}) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/$userId/reject',
        data: {
          'reason': reason,
          'rejection_reasons': rejectionReasons ?? {},
        },
      );
    } catch (e) {
      throw Exception('Failed to reject submission: $e');
    }
  }

  /// Reject User Kyc (PUT)
  Future<void> rejectUserKyc(int userId, String reason, {Map<String, dynamic>? rejectionReasons}) async {
    try {
      await _api.put(
        '/api/v1/admin/kyc/$userId/reject',
        data: {
          'reason': reason,
          'rejection_reasons': rejectionReasons ?? {},
        },
      );
    } catch (e) {
      throw Exception('Failed to reject user KYC: $e');
    }
  }

  /// Approve User Kyc (PUT)
  Future<void> approveUserKyc(int userId) async {
    try {
      await _api.put('/api/v1/admin/kyc/$userId/approve');
    } catch (e) {
      throw Exception('Failed to approve user KYC: $e');
    }
  }

  /// Complete Video KYC session
  Future<void> completeVideoKyc(
    int sessionId, {
    required String verificationResult,
    String? recordingLink,
    String? agentNotes,
  }) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/video-kyc/$sessionId/complete',
        data: {
          'verification_result': verificationResult,
          'recording_link': recordingLink,
          'agent_notes': agentNotes,
        },
      );
    } catch (e) {
      throw Exception('Failed to complete video KYC: $e');
    }
  }

  /// Admin KYC Dashboard metrics
  Future<Map<String, dynamic>> getKycDashboard() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/dashboard');
      return response.data;
    } catch (e) {
      print("Error fetching KYC dashboard: $e");
      return {
        'total_pending': 0,
        'total_approved_today': 0,
        'total_rejected_today': 0,
        'submission_trend': {},
      };
    }
  }
}
