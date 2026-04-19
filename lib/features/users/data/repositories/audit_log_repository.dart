import '../../../../core/api/api_client.dart';
import '../models/audit_log.dart';
import '../../../../core/api/api_client.dart';
import 'package:dio/dio.dart';

class AuditLogRepository {
  final ApiClient _apiClient;

  AuditLogRepository(this._apiClient);

  static final List<AuditLog> _logs = [
    AuditLog(id: '1', userId: 1, userName: 'Murari Varma', action: 'login', module: 'auth', details: 'Admin login successful', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    AuditLog(id: '2', userId: 1, userName: 'Murari Varma', action: 'update', module: 'users', details: 'Updated user profile for Rahul Sharma', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(minutes: 15)), beforeValue: 'role: driver', afterValue: 'role: driver'),
    AuditLog(id: '3', userId: 7, userName: 'Deepak Verma', action: 'kyc_reject', module: 'kyc', details: 'Rejected KYC for Suresh Kumar — blurry document', ipAddress: '103.55.90.12', userAgent: 'Firefox 121 / Mac', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    AuditLog(id: '4', userId: 1, userName: 'Murari Varma', action: 'suspend', module: 'users', details: 'Suspended Kavita Reddy — fraud suspected', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    AuditLog(id: '5', userId: 1, userName: 'Murari Varma', action: 'permission_change', module: 'roles', details: 'Removed finance.manage from Supervisor role', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(hours: 8)), beforeValue: 'finance.manage: true', afterValue: 'finance.manage: false'),
    AuditLog(id: '6', userId: 8, userName: 'Neha Gupta', action: 'login', module: 'auth', details: 'Support staff login', ipAddress: '172.20.10.5', userAgent: 'Edge 120 / Windows', timestamp: DateTime.now().subtract(const Duration(hours: 10))),
    AuditLog(id: '7', userId: 7, userName: 'Deepak Verma', action: 'kyc_approve', module: 'kyc', details: 'Approved KYC for Amit Patel', ipAddress: '103.55.90.12', userAgent: 'Firefox 121 / Mac', timestamp: DateTime.now().subtract(const Duration(days: 1))),
    AuditLog(id: '8', userId: 1, userName: 'Murari Varma', action: 'create', module: 'users', details: 'Created new user account for Vikram Malhotra', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3))),
    AuditLog(id: '9', userId: 1, userName: 'Murari Varma', action: 'update', module: 'settings', details: 'Updated platform timezone to IST', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 2))),
    AuditLog(id: '10', userId: 7, userName: 'Deepak Verma', action: 'reactivate', module: 'users', details: 'Reactivated account for Suresh Kumar', ipAddress: '103.55.90.12', userAgent: 'Firefox 121 / Mac', timestamp: DateTime.now().subtract(const Duration(days: 3))),
    AuditLog(id: '11', userId: 1, userName: 'Murari Varma', action: 'delete', module: 'users', details: 'Deleted inactive test account', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 4))),
    AuditLog(id: '12', userId: 8, userName: 'Neha Gupta', action: 'logout', module: 'auth', details: 'Support staff logout', ipAddress: '172.20.10.5', userAgent: 'Edge 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 6))),
  ];

  Future<List<AuditLog>> getLogs({
    String? action,
    String? module,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{};
    if (action != null && action != 'all') queryParams['action'] = action;
    if (module != null && module != 'all') queryParams['module'] = module;
    if (userId != null) queryParams['user_id'] = userId;
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

    try {
      final res = await _apiClient.get('/admin/audit-logs', queryParameters: queryParams);
      if (res.data != null && res.data is List) {
        return (res.data as List)
            .map<AuditLog>((e) => AuditLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Fallback
      try {
        final response = await _apiClient.get('/api/v1/admin/audit/data-access', queryParameters: queryParams);
        final List data = response.data['logs'] ?? [];
        return data.map((json) => AuditLog.fromJson(json)).toList();
      } catch (e) {
        print('Error fetching audit logs: $e');
        return List<AuditLog>.from(_logs);
      }
    }
    return List<AuditLog>.from(_logs);
  }

  Future<List<AuditLog>> getUserAuditLog(int userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get('/api/v1/admin/audit/users/$userId', queryParameters: {'page': page, 'limit': limit});
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user audit logs: $e');
      return [];
    }
  }

  Future<List<AuditLog>> getRoleAuditLog(int roleId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get('/api/v1/admin/audit/roles/$roleId/changes', queryParameters: {'page': page, 'limit': limit});
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching role audit logs: $e');
      return [];
    }
  }

  Future<dynamic> getPermissionUsage() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/audit/permissions/usage');
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
      
      final response = await _apiClient.get('/api/v1/admin/audit/auth/failures', queryParameters: queryParams);
      final List data = response.data['logs'] ?? [];
      return data.map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching auth failures: $e');
      return [];
    }
  }

  /// Fetch audit configuration including supported actions and modules.
  Future<Map<String, List<String>>> getAuditConfig() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/audit/config');
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
      
      await _apiClient.post('/api/v1/admin/audit/export', data: data);
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
