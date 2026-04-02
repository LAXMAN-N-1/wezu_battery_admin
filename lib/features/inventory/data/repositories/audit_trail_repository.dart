import '../../../../core/api/api_client.dart';
import '../models/audit_trail_model.dart';

class AuditTrailRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getAuditTrails({
    int skip = 0,
    int limit = 50,
    String? actionType,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (actionType != null) params['action_type'] = actionType;
      if (search != null) params['search'] = search;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;

      final response = await _api.get('/api/v1/admin/audit-trails/', queryParameters: params);
      final data = response.data;
      final entries = (data['entries'] as List).map((e) => AuditTrailEntry.fromJson(e)).toList();
      return {'entries': entries, 'total_count': data['total_count'] ?? 0};
    } catch (e) {
      throw Exception('Failed to fetch audit trails: $e');
    }
  }

  Future<AuditTrailStats> getStats() async {
    try {
      final response = await _api.get('/api/v1/admin/audit-trails/stats');
      return AuditTrailStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch audit trail stats: $e');
    }
  }
}
