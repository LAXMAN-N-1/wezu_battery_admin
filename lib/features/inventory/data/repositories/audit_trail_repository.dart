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
      print('Error fetching audit trails: $e');
      return {'entries': <AuditTrailEntry>[], 'total_count': 0};
    }
  }

  Future<AuditTrailStats> getStats() async {
    try {
      final response = await _api.get('/api/v1/admin/audit-trails/stats');
      return AuditTrailStats.fromJson(response.data);
    } catch (e) {
      print('Error fetching audit stats: $e');
      return AuditTrailStats(totalEntries: 0, todayCount: 0, weekCount: 0, transfers: 0, disposals: 0, statusChanges: 0, manualEntries: 0);
    }
  }
}
