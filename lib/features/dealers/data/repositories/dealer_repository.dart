import '../../../../core/api/api_client.dart';
import '../models/dealer.dart';
import '../models/dealer_application.dart';
import '../models/commission.dart';

class DealerRepository {
  final ApiClient _api;
  DealerRepository([ApiClient? api]) : _api = api ?? ApiClient();

  Future<Map<String, dynamic>> getDealers({
    int skip = 0,
    int limit = 25,
    String? search,
    String? city,
  }) async {
    final Map<String, dynamic> params = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (search != null) params['search'] = search;
    if (city != null) params['city'] = city;

    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/',
        queryParameters: params,
      );
      return {
        'dealers': (response.data['dealers'] as List)
            .map((d) => DealerProfile.fromJson(d))
            .toList(),
        'total_count': response.data['total_count'],
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<DealerStats> getDealerStats() async {
    try {
      final response = await _api.get('/api/v1/admin/dealers/stats');
      return DealerStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DealerApplication>> getApplications({String? stage}) async {
    final params = stage != null ? {'stage': stage} : null;
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/applications',
        queryParameters: params,
      );
      final payload = response.data;
      final rows = payload is Map<String, dynamic>
          ? (payload['applications'] as List? ?? const [])
          : (payload as List? ?? const []);
      return rows
          .map((a) => DealerApplication.fromJson(Map<String, dynamic>.from(a)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateApplicationStage(
    int appId,
    String stage, {
    String? notes,
  }) async {
    try {
      await _api.put(
        '/api/v1/admin/dealers/applications/$appId/stage',
        data: {'stage': stage, 'notes': notes},
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DealerKycDocument>> getKycDocuments() async {
    try {
      final response = await _api.get('/api/v1/admin/dealers/kyc');
      return (response.data as List)
          .map((d) => DealerKycDocument.fromJson(d))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyDocument(int docId, bool isVerified) async {
    try {
      await _api.put(
        '/api/v1/admin/dealers/documents/$docId/verify',
        queryParameters: {'is_verified': isVerified},
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CommissionConfig>> getCommissionConfigs() async {
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/commissions/configs',
      );
      return (response.data as List)
          .map((c) => CommissionConfig.fromJson(c))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateCommissionConfig(
    int configId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _api.put(
        '/api/v1/admin/dealers/commissions/configs/$configId',
        data: data,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CommissionLog>> getCommissionLogs({
    int skip = 0,
    int limit = 50,
  }) async {
    final Map<String, dynamic> params = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/commissions/logs',
        queryParameters: params,
      );
      return (response.data as List)
          .map((l) => CommissionLog.fromJson(l))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommissionStats() async {
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/commissions/stats',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> createDealer(Map<String, dynamic> data) async {
    try {
      await _api.post('/api/v1/admin/dealers/create', data: data);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateDealer(int dealerId, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/v1/admin/dealers/$dealerId', data: data);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDealerDetail(int dealerId) async {
    try {
      final response = await _api.get('/api/v1/admin/dealers/$dealerId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllDocuments({
    String? search,
    String? docType,
  }) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    if (docType != null) params['doc_type'] = docType;
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/documents/all',
        queryParameters: params,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> createCommissionConfig(Map<String, dynamic> data) async {
    try {
      await _api.post('/api/v1/admin/dealers/commissions/configs', data: data);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDealerInventory(
    int dealerId, {
    int page = 1,
    int limit = 50,
    String? status,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/$dealerId/inventory',
        queryParameters: params,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDealerInventoryMetrics(int dealerId) async {
    try {
      final response = await _api.get(
        '/api/v1/admin/dealers/$dealerId/inventory/metrics',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
