import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/kyc_document.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(ref.watch(apiClientProvider));
});

class KycRepository {
  final ApiClient _api;

  KycRepository(this._api);

  /// List all users with pending KYC verification
  Future<Map<String, dynamic>> getPendingQueue({int page = 1, int size = 10, String? userType}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (userType != null) queryParams['user_type'] = userType;

      final response = await _api.get('/api/v1/admin/kyc/pending', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      print("Error fetching KYC queue: $e");
      return {'items': [], 'total': 0};
    }
  }

  /// List all documents waiting for verification (direct list)
  Future<List<KycDocument>> getPendingDocuments() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/documents/pending');
      final List data = response.data ?? [];
      return data.map((json) => KycDocument.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching pending documents: $e");
      return [];
    }
  }

  /// Approve individual document
  Future<KycDocument?> approveDocument(int docId) async {
    try {
      final response = await _api.post('/api/v1/admin/kyc/documents/$docId/approve');
      return KycDocument.fromJson(response.data);
    } catch (e) {
      print('Error approving document: $e');
      return null;
    }
  }

  /// Reject individual document
  Future<KycDocument?> rejectDocument(int docId, String reason) async {
    try {
      final response = await _api.post(
        '/api/v1/admin/kyc/documents/$docId/reject',
        data: {'reason': reason},
      );
      return KycDocument.fromJson(response.data);
    } catch (e) {
      print('Error rejecting document: $e');
      return null;
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

  /// Alternative Reject Submission (POST)
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

  /// Alternative Reject User Kyc (PUT)
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

  /// Alternative Approve User Kyc (PUT)
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
