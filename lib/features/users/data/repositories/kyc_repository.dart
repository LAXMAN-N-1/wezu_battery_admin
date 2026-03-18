import '../../../../core/api/api_client.dart';
import '../models/kyc_document.dart';

class KycRepository {
  final ApiClient _api = ApiClient();

  Future<List<KycDocument>> getDocuments({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _api.get('/api/v1/admin/kyc/pending', queryParameters: queryParams);
      final items = response.data['items'] as List;

      List<KycDocument> documents = [];
      for (var user in items) {
        final userName = user['full_name'];
        final userEmail = user['email'];
        final docs = user['documents'] as List;

        for (var doc in docs) {
          documents.add(KycDocument.fromJson(
            doc,
            defaultUserName: userName,
            defaultUserEmail: userEmail,
          ));
        }
      }
      return documents;
    } catch (e) {
      print("Error fetching KYC queue: $e");
      return [];
    }
  }

  Future<List<KycDocument>> getDocumentsByUser(int userId) async {
    // Currently no dedicated endpoint for getting a specific user's documents
    // apart from the general pending queue. Returning empty for now.
    return [];
  }

  Future<void> approveDocument(int docId, String reviewNotes) async {
    try {
      await _api.post('/api/v1/admin/kyc/documents/$docId/approve');
    } catch (e) {
      throw Exception('Failed to approve document: $e');
    }
  }

  Future<void> rejectDocument(int docId, String reason) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/documents/$docId/reject',
        data: {'reason': reason},
      );
    } catch (e) {
      throw Exception('Failed to reject document: $e');
    }
  }

  /// List all documents waiting for verification (direct endpoint)
  Future<List<KycDocument>> getPendingDocuments() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/documents/pending');
      final data = response.data as List;
      return data.map((json) => KycDocument.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching pending documents: $e");
      return [];
    }
  }

  /// Approve/Reject a full KYC submission for a user
  Future<void> verifyKycSubmission(
    int userId, {
    required String decision,
    String? notes,
    Map<int, String>? rejectionReasons,
  }) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/$userId/verify',
        data: {
          'decision': decision,
          'notes': notes,
          'rejection_reasons': rejectionReasons,
        },
      );
    } catch (e) {
      throw Exception('Failed to verify KYC submission: $e');
    }
  }

  /// Admin: approve a user's KYC submission (alternative endpoint)
  Future<void> approveUserKyc(int userId) async {
    try {
      await _api.put('/api/v1/admin/kyc/$userId/approve');
    } catch (e) {
      throw Exception('Failed to approve user KYC: $e');
    }
  }

  /// Admin: reject KYC with mandatory reason code and notes (alternative endpoint)
  Future<void> rejectUserKyc(int userId, String reason, {Map<int, String>? rejectionReasons}) async {
    try {
      await _api.put(
        '/api/v1/admin/kyc/$userId/reject',
        data: {
          'reason': reason,
          'rejection_reasons': rejectionReasons,
        },
      );
    } catch (e) {
      throw Exception('Failed to reject user KYC: $e');
    }
  }

  /// Mark a Video KYC session as complete/verified
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

  Future<Map<String, dynamic>> getKycMetrics() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/dashboard');
      final data = response.data;

      final pending = data['total_pending'] ?? 0;
      final approved = data['total_approved_today'] ?? 0;
      final rejected = data['total_rejected_today'] ?? 0;
      final total = pending + approved + rejected;

      return {
        'total': total,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'manual_review': 0, // Not explicitly in dashboard response
        'approval_rate': total > 0 ? ((approved / total) * 100).round() : 0,
        'avg_processing_hours': 24, // Mocked if not in dashboard
        'submission_trend': data['submission_trend'] != null ? Map<String, dynamic>.from(data['submission_trend']) : {},
      };
    } catch (e) {
      print("Error fetching kyc metrics: $e");
      return {
        'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0,
        'manual_review': 0, 'approval_rate': 0, 'avg_processing_hours': 0,
        'submission_trend': {},
      };
    }
  }
}
