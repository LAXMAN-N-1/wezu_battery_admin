import '../../../../core/api/api_client.dart';
import '../models/audit_log.dart';

class AuditLogRepository {
  final ApiClient _api;

  AuditLogRepository(this._api);

  Future<List<AuditLog>> getLogs({
    String? action,
    String? module,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (userId != null) queryParams['user_id'] = userId;
      if (fromDate != null) queryParams['start_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['end_date'] = toDate.toIso8601String();
      if (module != null && module != 'all') queryParams['resource_type'] = module;

      final response = await _api.get('/api/v1/admin/audit/data-access', queryParameters: queryParams);
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromGenericJson(json)).toList();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  Future<List<AuditLog>> getUserAuditLog(int userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get('/api/v1/admin/audit/users/$userId', queryParameters: {'page': page, 'limit': limit});
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromUserAuditJson(json)).toList();
    } catch (e) {
      print('Error fetching user audit logs: $e');
      return [];
    }
  }

  Future<List<AuditLog>> getRoleAuditLog(int roleId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get('/api/v1/admin/audit/roles/$roleId/changes', queryParameters: {'page': page, 'limit': limit});
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromRoleAuditJson(json)).toList();
    } catch (e) {
      print('Error fetching role audit logs: $e');
      return [];
    }
  }

  Future<dynamic> getPermissionUsage() async {
    try {
      final response = await _api.get('/api/v1/admin/audit/permissions/usage');
      return response.data;
    } catch (e) {
      print('Error fetching permission usage: $e');
      return null;
    }
  }

  Future<List<AuditLog>> getAuthFailures({int? userId, int page = 1, int limit = 20}) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (userId != null) queryParams['user_id'] = userId;
      
      final response = await _api.get('/api/v1/admin/audit/auth/failures', queryParameters: queryParams);
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromGenericJson(json)).toList();
    } catch (e) {
      print('Error fetching auth failures: $e');
      return [];
    }
  }

  /// Fetch audit configuration including supported actions and modules.
  Future<Map<String, List<String>>> getAuditConfig() async {
    try {
      final response = await _api.get('/api/v1/admin/audit/config');
      return {
        'actions': List<String>.from(response.data['actions'] ?? []),
        'modules': List<String>.from(response.data['modules'] ?? []),
      };
    } catch (e) {
      print('Error fetching audit config: $e');
      return {
        'actions': ['all', 'login', 'logout', 'create', 'update', 'delete', 'suspend', 'reactivate', 'kyc_approve', 'kyc_reject', 'permission_change'],
        'modules': ['all', 'auth', 'users', 'kyc', 'roles', 'settings', 'fleet', 'finance'],
      };
    }
  }

  /// Trigger a server-side audit log export.
  Future<bool> exportLogs({String? action, String? module}) async {
    try {
      final data = <String, dynamic>{};
      if (action != null && action != 'all') data['action'] = action;
      if (module != null && module != 'all') data['resource_type'] = module;
      
      await _api.post('/api/v1/admin/audit/export', data: data);
      return true;
    } catch (e) {
      print('Error exporting audit logs: $e');
      return false;
    }
  }

  Future<List<String>> getActionTypes() async {
    final config = await getAuditConfig();
    return ['all', ...config['actions']!];
  }

  Future<List<String>> getModules() async {
    final config = await getAuditConfig();
    return ['all', ...config['modules']!];
  }
}
