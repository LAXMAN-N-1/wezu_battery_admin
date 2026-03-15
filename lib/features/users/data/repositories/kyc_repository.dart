import '../../../../core/api/api_client.dart';
import '../models/kyc_model.dart';

class KYCRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getDocuments({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (status != null) params['status'] = status;

    try {
      final response = await _api.get('/api/v1/admin/kyc-docs/', queryParameters: params);
      final data = response.data;
      final docs = (data['documents'] as List)
          .map((d) => KYCDocument.fromJson(d))
          .toList();
      return {
        'documents': docs,
        'total_count': data['total_count'] ?? docs.length,
      };
    } catch (e) {
      return {'documents': <KYCDocument>[], 'total_count': 0};
    }
  }

  Future<KYCStats> getStats() async {
    try {
      final response = await _api.get('/api/v1/admin/kyc-docs/stats');
      return KYCStats.fromJson(response.data);
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

  Future<bool> approveDocument(int docId) async {
    try {
      await _api.put('/api/v1/admin/kyc-docs/$docId/approve');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectDocument(int docId, String reason) async {
    try {
      await _api.put('/api/v1/admin/kyc-docs/$docId/reject', data: {'reason': reason});
      return true;
    } catch (e) {
      return false;
    }
  }
}
