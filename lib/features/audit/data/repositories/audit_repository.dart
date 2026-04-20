import 'dart:async';
import '../../../../core/api/api_client.dart';
import '../models/audit_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditRepository {
  final ApiClient _apiClient;
  AuditRepository([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  static const String _securityBase = '/api/v1/admin/security';
  static const String _fraudBase = '/api/v1/admin/fraud';
  static const String _iotBase = '/api/v1/admin/iot';

  // --- 1. Security & Fraud Endpoints ---

  Future<Map<String, dynamic>> getSecurityEvents({
    String? severity,
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '$_securityBase/security-events',
      queryParameters: {
        if (severity != null && severity != 'All') 'severity': severity,
        'skip': skip,
        'limit': limit,
      },
    );
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return {
      'items': itemsRaw
          .map((json) => SecurityEventItem.fromJson(json))
          .toList(),
      'total': (response.data is Map)
          ? (response.data['total'] ??
                response.data['total_count'] ??
                itemsRaw.length)
          : itemsRaw.length,
    };
  }

  Future<void> resolveSecurityEvent(int eventId) async {
    await _apiClient.patch('$_securityBase/security-events/$eventId/resolve');
  }

  Future<Map<String, dynamic>> getFraudAlerts({
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '$_securityBase/fraud-alerts',
      queryParameters: {
        if (status != null && status != 'All') 'status': status,
        'skip': skip,
        'limit': limit,
      },
    );
    final List itemsRaw = (response.data is Map)
        ? (response.data['alerts'] ?? response.data['items'] ?? [])
        : (response.data ?? []);
    return {
      'items': itemsRaw.map((json) => FraudAlert.fromJson(json)).toList(),
      'total': (response.data is Map)
          ? (response.data['total'] ??
                response.data['total_count'] ??
                itemsRaw.length)
          : itemsRaw.length,
    };
  }

  Future<void> updateFraudAlertStatus(String alertId, String status) async {
    await _apiClient.patch(
      '$_securityBase/fraud-alerts/$alertId/status',
      data: {'status': status},
    );
  }

  Future<void> escalateFraudAlert(String alertId) async {
    await _apiClient.post('$_securityBase/fraud-alerts/$alertId/escalate');
  }

  Future<SecuritySettings> getSecuritySettings() async {
    try {
      final response = await _apiClient.get('$_securityBase/security-settings');
      return SecuritySettings.fromJson(response.data);
    } catch (_) {
      // Fallback for environments exposing only generic settings endpoint.
      final fallback = await _apiClient.get('/api/v1/admin/settings/general');
      return _buildSecuritySettingsFromGeneral(fallback.data);
    }
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> updates) async {
    try {
      await _apiClient.patch('$_securityBase/security-settings', data: updates);
    } catch (_) {
      // Graceful fallback for installations where security-settings API is not
      // deployed yet but generic settings is available.
      await _patchGeneralSecuritySettings(updates);
    }
  }

  Future<Map<String, dynamic>> getHighRiskUsers({
    int threshold = 50,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      '$_fraudBase/high-risk-users',
      queryParameters: {'threshold': threshold, 'limit': limit},
    );
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return {
      'items': itemsRaw,
      'total': (response.data is Map)
          ? (response.data['total'] ?? itemsRaw.length)
          : itemsRaw.length,
    };
  }

  Future<Map<String, dynamic>> getDuplicateAccounts() async {
    final response = await _apiClient.get('$_fraudBase/duplicate-accounts');
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return {'items': itemsRaw, 'total': itemsRaw.length};
  }

  Future<List<Map<String, dynamic>>> getBlacklist() async {
    final response = await _apiClient.get('$_fraudBase/blacklist');
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return List<Map<String, dynamic>>.from(itemsRaw);
  }

  Future<void> addToBlacklist(Map<String, dynamic> data) async {
    await _apiClient.post('$_fraudBase/blacklist', data: data);
  }

  Future<void> updateBlacklistEntry(
    int entryId,
    Map<String, dynamic> updates,
  ) async {
    await _apiClient.patch('$_fraudBase/blacklist/$entryId', data: updates);
  }

  Future<void> removeFromBlacklist(int entryId) async {
    await _apiClient.delete('$_fraudBase/blacklist/$entryId');
  }

  Future<List<Map<String, dynamic>>> getDeviceFingerprints() async {
    final response = await _apiClient.get('$_fraudBase/device-fingerprints');
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return List<Map<String, dynamic>>.from(itemsRaw);
  }

  Future<Map<String, dynamic>> verifyIdentity(String type, String value) async {
    final response = await _apiClient.post(
      '$_fraudBase/verify/$type',
      data: {'value': value},
    );
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
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
    if (action != null && action != 'All') queryParams['action'] = action;
    if (severity != null && severity != 'All')
      queryParams['severity'] = severity;
    if (status != null && status != 'All') queryParams['status'] = status;
    if (role != null && role != 'All') queryParams['role'] = role;
    if (startDate != null)
      queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    final response = await _apiClient.get(
      '$_securityBase/audit-logs',
      queryParameters: queryParams,
    );

    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    final List<AuditLogItem> items = itemsRaw
        .map((json) => AuditLogItem.fromJson(json))
        .toList();

    return {
      'items': items,
      'total': (response.data is Map)
          ? (response.data['total'] ??
                response.data['total_count'] ??
                items.length)
          : items.length,
      'has_more': (response.data is Map)
          ? (response.data['has_more'] ?? false)
          : false,
    };
  }

  Future<Map<String, dynamic>> getAuditStats() async {
    final response = await _apiClient.get('$_securityBase/audit-logs/stats');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> exportAuditLogs({String? action, String? module}) async {
    await _apiClient.post(
      '$_securityBase/audit-logs/export',
      data: {'action': action, 'module': module},
    );
  }

  Future<void> flagAuditLogSuspicious(int logId, String reason) async {
    await _apiClient.patch(
      '$_securityBase/audit-logs/$logId/flag',
      data: {'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> getAuditTrails() async {
    final response = await _apiClient.get('/api/v1/admin/audit-trails/');
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return List<Map<String, dynamic>>.from(itemsRaw);
  }

  // --- Utility Methods ---

  Future<void> forceLogoutAllAdmins() async {
    await _apiClient.post('$_securityBase/force-logout-all');
  }

  Future<void> revokeAllApiTokens() async {
    await _apiClient.post('$_securityBase/revoke-api-tokens');
  }

  Future<void> saveInvestigationNote(String alertId, String content) async {
    await _apiClient.post(
      '$_securityBase/fraud-alerts/$alertId/notes',
      data: {'content': content},
    );
  }

  Future<void> blockUser(int userId, String reason) async {
    await _apiClient.post(
      '/api/v1/admin/users/$userId/ban',
      queryParameters: {'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> getSecurityOriginMetrics() async {
    final response = await _apiClient.get('$_securityBase/dashboard/origins');
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return List<Map<String, dynamic>>.from(itemsRaw);
  }

  Future<Map<String, dynamic>> getSecurityDashboard() async {
    final response = await _apiClient.get('$_securityBase/dashboard');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getGeofences() async {
    final response = await _apiClient.get('$_iotBase/geofences');
    final List itemsRaw = (response.data is Map)
        ? (response.data['items'] ?? [])
        : (response.data ?? []);
    return List<Map<String, dynamic>>.from(itemsRaw);
  }

  SecuritySettings _buildSecuritySettingsFromGeneral(dynamic rawData) {
    if (rawData is! Map) {
      return SecuritySettings.defaultSettings();
    }
    final data = Map<String, dynamic>.from(rawData);
    final defaults = SecuritySettings.defaultSettings();

    int readInt(String key, int fallback) {
      final value = (data[key] is Map) ? data[key]['value'] : null;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool readBool(String key, bool fallback) {
      final value = (data[key] is Map) ? data[key]['value'] : null;
      final normalized = value?.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
      return fallback;
    }

    return defaults.copyWith(
      sessionMgmt: defaults.sessionMgmt.copyWith(
        timeoutMinutes: readInt(
          'session_timeout_minutes',
          defaults.sessionMgmt.timeoutMinutes,
        ),
      ),
      twoFactor: defaults.twoFactor.copyWith(
        enabled: readBool('2fa_enabled', defaults.twoFactor.enabled),
      ),
      loginControls: defaults.loginControls.copyWith(
        maxFailedAttempts: readInt(
          'max_login_attempts',
          defaults.loginControls.maxFailedAttempts,
        ),
      ),
    );
  }

  Future<void> _patchGeneralSecuritySettings(
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.get('/api/v1/admin/settings/general');
    if (response.data is! Map) {
      return;
    }

    final general = Map<String, dynamic>.from(response.data);
    final session =
        updates['session_mgmt'] as Map<String, dynamic>? ?? const {};
    final login =
        updates['login_controls'] as Map<String, dynamic>? ?? const {};
    final twoFactor =
        updates['two_factor'] as Map<String, dynamic>? ?? const {};

    final fallbackPatches = <String, String>{
      if (session['timeout_minutes'] != null)
        'session_timeout_minutes': session['timeout_minutes'].toString(),
      if (login['max_failed_attempts'] != null)
        'max_login_attempts': login['max_failed_attempts'].toString(),
      if (twoFactor['enabled'] != null)
        '2fa_enabled': (twoFactor['enabled'] as bool).toString(),
    };

    for (final entry in fallbackPatches.entries) {
      final item = general[entry.key];
      if (item is Map && item['id'] != null) {
        await _apiClient.patch(
          '/api/v1/admin/settings/general/${item['id']}',
          queryParameters: {'value': entry.value},
        );
      }
    }
  }
}

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(),
);
