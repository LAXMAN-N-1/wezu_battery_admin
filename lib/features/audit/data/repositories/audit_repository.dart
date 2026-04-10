import 'dart:async';
import '../../../../core/api/api_client.dart';
import '../models/audit_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditRepository {
  final ApiClient _apiClient;
  AuditRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  
  static const String _securityBase = '/api/v1/admin/security';
  static const String _fraudBase = '/api/v1/admin/fraud';
  static const String _iotBase = '/api/v1/admin/iot';

  // --- 1. Security & Fraud Endpoints ---

  Future<Map<String, dynamic>> getSecurityEvents({String? severity, int skip = 0, int limit = 50}) async {
    final response = await _apiClient.get('$_securityBase/security-events', queryParameters: {
      if (severity != null && severity != 'All') 'severity': severity,
      'skip': skip,
      'limit': limit,
    });
    final List itemsRaw = response.data['items'] ?? [];
    return {
      'items': itemsRaw.map((json) => SecurityEventItem.fromJson(json)).toList(),
      'total': response.data['total'] ?? itemsRaw.length,
    };
  }

  Future<void> resolveSecurityEvent(int eventId) async {
    await _apiClient.patch('$_securityBase/security-events/$eventId/resolve');
  }

  Future<List<FraudAlert>> getFraudAlerts({int skip = 0, int limit = 50}) async {
    final response = await _apiClient.get('$_securityBase/fraud-alerts', queryParameters: {
      'skip': skip,
      'limit': limit,
    });
    final List data = response.data is List ? response.data : (response.data['alerts'] ?? response.data['items'] ?? []);
    return data.map((json) => FraudAlert.fromJson(json)).toList();
  }

  Future<void> updateFraudAlertStatus(String alertId, String status) async {
    await _apiClient.patch('$_securityBase/fraud-alerts/$alertId/status', data: {'status': status});
  }

  Future<void> escalateFraudAlert(String alertId) async {
    await _apiClient.post('$_securityBase/fraud-alerts/$alertId/escalate');
  }

  Future<SecuritySettings> getSecuritySettings() async {
    final response = await _apiClient.get('$_securityBase/security-settings');
    return SecuritySettings.fromJson(response.data);
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> updates) async {
    await _apiClient.patch('$_securityBase/security-settings', data: updates);
  }

  Future<List<Map<String, dynamic>>> getHighRiskUsers({int threshold = 50, int limit = 100}) async {
    final response = await _apiClient.get('$_fraudBase/high-risk-users', queryParameters: {
      'threshold': threshold,
      'limit': limit,
    });
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getDuplicateAccounts() async {
    final response = await _apiClient.get('$_fraudBase/duplicate-accounts');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getBlacklist() async {
    final response = await _apiClient.get('$_fraudBase/blacklist');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> addToBlacklist(Map<String, dynamic> data) async {
    await _apiClient.post('$_fraudBase/blacklist', data: data);
  }

  Future<void> updateBlacklistEntry(int entryId, Map<String, dynamic> updates) async {
    await _apiClient.patch('$_fraudBase/blacklist/$entryId', data: updates);
  }

  Future<void> removeFromBlacklist(int entryId) async {
    await _apiClient.delete('$_fraudBase/blacklist/$entryId');
  }

  Future<List<Map<String, dynamic>>> getDeviceFingerprints() async {
    final response = await _apiClient.get('$_fraudBase/device-fingerprints');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> verifyIdentity(String type, String value) async {
    final response = await _apiClient.post('$_fraudBase/verify/$type', data: {'value': value});
    return response.data;
  }

  // --- 2. Audit Trail & Log Endpoints ---

  Future<Map<String, dynamic>> getAuditLogs({
    String? action, 
    String? severity, 
    String? status,
    String? role,
    DateTime? startDate,
    DateTime? endDate,
    String? query, 
    int skip = 0, 
    int limit = 50
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
      'days': 30,
    };
    if (action != null && action != 'All') queryParams['action'] = action;
    if (severity != null && severity != 'All') queryParams['severity'] = severity;
    if (status != null && status != 'All') queryParams['status'] = status;
    if (role != null && role != 'All') queryParams['role'] = role;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    final response = await _apiClient.get('$_securityBase/audit-logs', queryParameters: queryParams);
    
    final List itemsRaw = response.data['items'] ?? [];
    final List<AuditLogItem> items = itemsRaw.map((json) => AuditLogItem.fromJson(json)).toList();
    
    return {
      'items': items,
      'total': response.data['total'] ?? response.data['total_count'] ?? items.length,
      'has_more': response.data['has_more'] ?? false,
    };
  }

  Future<Map<String, dynamic>> getAuditStats() async {
    final response = await _apiClient.get('$_securityBase/audit-logs/stats');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> exportAuditLogs({String? action, String? module}) async {
    await _apiClient.post('$_securityBase/audit-logs/export', data: {
      'action': action,
      'module': module,
    });
  }

  Future<void> flagAuditLogSuspicious(int logId, String reason) async {
    await _apiClient.patch('$_securityBase/audit-logs/$logId/flag', data: {'reason': reason});
  }

  Future<List<Map<String, dynamic>>> getAuditTrails() async {
    final response = await _apiClient.get('/api/v1/admin/audit-trails/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // --- Utility Methods ---

  Future<void> saveInvestigationNote(String alertId, String content) async {
    await _apiClient.post('$_securityBase/fraud-alerts/$alertId/notes', data: {
      'content': content,
    });
  }
  
  Future<void> blockUser(int userId, String reason) async {
    await _apiClient.post('/api/v1/admin/users/$userId/ban', queryParameters: {'reason': reason});
  }

  Future<List<Map<String, dynamic>>> getSecurityOriginMetrics() async {
    final response = await _apiClient.get('$_securityBase/dashboard/origins');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getSecurityDashboard() async {
    final response = await _apiClient.get('$_securityBase/dashboard');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getGeofences() async {
    final response = await _apiClient.get('$_iotBase/geofences');
    return List<Map<String, dynamic>>.from(response.data);
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) => AuditRepository());
