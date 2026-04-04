import '../../../../core/api/api_client.dart';
import '../models/audit_models.dart';

class AuditRepository {
  final ApiClient _apiClient;
  AuditRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/security';

  Future<Map<String, dynamic>> getAuditLogs({String? action, String? resourceType, int? userId, int skip = 0}) async {
    final r = await _apiClient.get('$_base/audit-logs', queryParameters: {
      'skip': skip.toString(),
      if (action != null) 'action': action,
      if (resourceType != null) 'resource_type': resourceType,
      if (userId != null) 'user_id': userId.toString(),
    });
    return {
      'items': (r.data['items'] as List).map((e) => AuditLogItem.fromJson(e)).toList(),
      'total_count': r.data['total_count'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> getAuditStats() async {
    final r = await _apiClient.get('$_base/audit-logs/stats');
    return r.data;
  }

  Future<Map<String, dynamic>> getSecurityEvents({String? severity, String? eventType, bool? isResolved, int skip = 0}) async {
    final r = await _apiClient.get('$_base/security-events', queryParameters: {
      'skip': skip.toString(),
      if (severity != null) 'severity': severity,
      if (eventType != null) 'event_type': eventType,
      if (isResolved != null) 'is_resolved': isResolved.toString(),
    });
    return {
      'items': (r.data['items'] as List).map((e) => SecurityEventItem.fromJson(e)).toList(),
      'total_count': r.data['total_count'] ?? 0,
    };
  }

  Future<void> resolveSecurityEvent(int eventId) async {
    await _apiClient.patch('$_base/security-events/$eventId/resolve');
  }

  Future<Map<String, dynamic>> getSecuritySettings() async {
    final r = await _apiClient.get('$_base/security-settings');
    return r.data;
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> updates) async {
    await _apiClient.patch('$_base/security-settings', queryParameters: updates);
  }
}
