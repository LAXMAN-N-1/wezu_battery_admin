import '../../../../core/api/api_client.dart';
import '../models/kyc_document.dart';
import '../models/kyc_model.dart';

Future<Map<String, dynamic>> _fetchDocumentsPayload(ApiClient apiClient, {String? status}) async {
  final response = await apiClient.get(
    '/api/v1/admin/kyc/documents',
    queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
    },
  );

  if (response.data is Map<String, dynamic>) {
    return response.data as Map<String, dynamic>;
  }

  if (response.data is Map) {
    return Map<String, dynamic>.from(response.data as Map);
  }

  return {
    'documents': const <dynamic>[],
    'total_count': 0,
  };
}

List<KycDocument> _toKycDocuments(List<dynamic> rawDocuments) {
  return rawDocuments
      .whereType<Map>()
      .map(
        (json) => KycDocument.fromJson(
          Map<String, dynamic>.from(json),
          defaultUserName: json['user_name']?.toString(),
          defaultUserEmail: json['user_email']?.toString(),
        ),
      )
      .toList();
}

List<KYCDocument> _toLegacyKycDocuments(List<dynamic> rawDocuments) {
  return rawDocuments
      .whereType<Map>()
      .map((json) => KYCDocument.fromJson(Map<String, dynamic>.from(json)))
      .toList();
}

class KycRepository {
  final ApiClient _api;

  KycRepository([ApiClient? apiClient]) : _api = apiClient ?? ApiClient();

  Future<List<KycDocument>> getDocuments({String? status}) async {
    try {
      final payload = await _fetchDocumentsPayload(_api, status: status);
      final rawDocuments = payload['documents'] as List? ?? const <dynamic>[];
      return _toKycDocuments(rawDocuments);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getKycMetrics() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/stats');
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final total = data['total_documents'] ?? 0;
      final pending = data['total_pending'] ?? 0;
      final approved = data['total_verified'] ?? 0;
      final rejected = data['total_rejected'] ?? 0;

      return {
        'total': total,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'manual_review': 0,
        'approval_rate': total > 0 ? ((approved / total) * 100).round() : 0,
        'avg_processing_hours': 24,
        'submission_trend': const <String, dynamic>{},
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'manual_review': 0,
        'approval_rate': 0,
        'avg_processing_hours': 0,
        'submission_trend': const <String, dynamic>{},
      };
    }
  }

  Future<bool> approveDocument(int docId, [String? reviewNotes]) async {
    try {
      await _api.post('/api/v1/admin/kyc/documents/$docId/approve');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectDocument(int docId, String reason) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/documents/$docId/reject',
        data: {'reason': reason},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> verifyKycSubmission(
    int userId, {
    required String decision,
    String? notes,
    Map<int, String>? rejectionReasons,
  }) async {
    await _api.post(
      '/api/v1/admin/kyc/$userId/verify',
      data: {
        'decision': decision,
        'notes': notes,
        'rejection_reasons': rejectionReasons,
      },
    );
  }
}

class KYCRepository {
  final ApiClient _api;

  KYCRepository([ApiClient? apiClient]) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getDocuments({String? status}) async {
    try {
      final payload = await _fetchDocumentsPayload(_api, status: status);
      final rawDocuments = payload['documents'] as List? ?? const <dynamic>[];

      return {
        'documents': _toLegacyKycDocuments(rawDocuments),
        'total_count': payload['total_count'] ?? rawDocuments.length,
      };
    } catch (e) {
      return {
        'documents': <KYCDocument>[],
        'total_count': 0,
      };
    }
  }

  Future<KYCStats> getStats() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc/stats');
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      return KYCStats.fromJson(data);
    } catch (e) {
      return const KYCStats(
        totalDocuments: 0,
        totalPending: 0,
        totalVerified: 0,
        totalRejected: 0,
        pendingUsers: 0,
      );
    }
  }

  Future<bool> approveDocument(int docId, [String? reviewNotes]) async {
    try {
      await _api.post('/api/v1/admin/kyc/documents/$docId/approve');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectDocument(int docId, String reason) async {
    try {
      await _api.post(
        '/api/v1/admin/kyc/documents/$docId/reject',
        data: {'reason': reason},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
