import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/audit_models.dart';

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

class AuditRepository {
  final ApiClient _apiClient;
  AuditRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _securityBase = '/api/v1/admin/security';
  static const String _fraudBase = '/api/v1/admin/fraud';
  static const String _iotBase = '/api/v1/admin/iot';

  // --- 1. Security & Fraud Endpoints ---

  Future<Map<String, dynamic>> getSecurityEvents({
    String? severity,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _getAny(
        <String>[
          '$_securityBase/security-events',
          '$_securityBase/activity-logs',
        ],
        queryParameters: <String, dynamic>{
          if (severity != null && severity != 'All') 'severity': severity,
          'skip': skip,
          'offset': skip,
          'limit': limit,
        },
      );

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['events'] ?? map['logs']),
      );

      final items = rows
          .whereType<Map>()
          .map((json) => SecurityEventItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      return <String, dynamic>{
        'items': items,
        'total': _toInt(map['total'] ?? map['total_count'] ?? items.length),
      };
    } catch (_) {
      return <String, dynamic>{'items': <SecurityEventItem>[], 'total': 0};
    }
  }

  Future<void> resolveSecurityEvent(int eventId) async {
    try {
      await _patchAny(<String>['$_securityBase/security-events/$eventId/resolve']);
    } catch (_) {
      // Ignore gracefully when endpoint is unavailable.
    }
  }

  Future<Map<String, dynamic>> getFraudAlerts({
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _getAny(
        <String>[
          '$_securityBase/fraud-alerts',
          '$_fraudBase/alerts',
          '/api/v1/admin/main/fraud/high-risk-users',
        ],
        queryParameters: <String, dynamic>{
          if (status != null && status != 'All') 'status': status,
          'skip': skip,
          'offset': skip,
          'limit': limit,
        },
      );

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty
            ? response.data
            : (map['alerts'] ?? map['items'] ?? map['data']),
      );

      final items = rows
          .whereType<Map>()
          .map((json) => FraudAlert.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      return <String, dynamic>{
        'items': items,
        'total': _toInt(map['total'] ?? map['total_count'] ?? items.length),
      };
    } catch (_) {
      return <String, dynamic>{'items': <FraudAlert>[], 'total': 0};
    }
  }

  Future<void> updateFraudAlertStatus(String alertId, String status) async {
    try {
      await _patchAny(
        <String>['$_securityBase/fraud-alerts/$alertId/status'],
        data: <String, dynamic>{'status': status},
      );
    } catch (_) {}
  }

  Future<void> escalateFraudAlert(String alertId) async {
    try {
      await _postAny(<String>['$_securityBase/fraud-alerts/$alertId/escalate']);
    } catch (_) {}
  }

  Future<SecuritySettings> getSecuritySettings() async {
    try {
      final response = await _getAny(<String>['$_securityBase/security-settings']);
      return SecuritySettings.fromJson(_asMap(response.data));
    } catch (_) {
      return SecuritySettings.defaultSettings();
    }
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> updates) async {
    try {
      await _patchAny(<String>['$_securityBase/security-settings'], data: updates);
    } catch (_) {
      // Keep UX stable when backend settings endpoint is missing.
    }
  }

  Future<Map<String, dynamic>> getHighRiskUsers({
    int threshold = 50,
    int limit = 100,
  }) async {
    try {
      final response = await _getAny(
        <String>[
          '$_fraudBase/high-risk-users',
          '/api/v1/admin/main/fraud/high-risk-users',
        ],
        queryParameters: <String, dynamic>{'threshold': threshold, 'limit': limit},
      );

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['data']),
      );

      return <String, dynamic>{
        'items': rows,
        'total': _toInt(map['total'] ?? map['total_count'] ?? rows.length),
      };
    } catch (_) {
      return <String, dynamic>{'items': <dynamic>[], 'total': 0};
    }
  }

  Future<Map<String, dynamic>> getDuplicateAccounts() async {
    try {
      final response = await _getAny(<String>[
        '$_fraudBase/duplicate-accounts',
        '/api/v1/admin/main/fraud/duplicate-accounts',
      ]);
      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['data']),
      );
      return <String, dynamic>{'items': rows, 'total': rows.length};
    } catch (_) {
      return <String, dynamic>{'items': <dynamic>[], 'total': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getBlacklist() async {
    try {
      final response = await _getAny(<String>[
        '$_fraudBase/blacklist',
        '/api/v1/admin/main/fraud/blacklist',
      ]);
      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['data']),
      );
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> addToBlacklist(Map<String, dynamic> data) async {
    try {
      await _postAny(<String>[
        '$_fraudBase/blacklist',
        '/api/v1/admin/main/fraud/blacklist',
      ], data: data);
    } catch (_) {}
  }

  Future<void> updateBlacklistEntry(int entryId, Map<String, dynamic> updates) async {
    try {
      await _patchAny(<String>[
        '$_fraudBase/blacklist/$entryId',
        '/api/v1/admin/main/fraud/blacklist/$entryId',
      ], data: updates);
    } catch (_) {}
  }

  Future<void> removeFromBlacklist(int entryId) async {
    try {
      await _apiClient.delete('$_fraudBase/blacklist/$entryId');
    } catch (_) {
      try {
        await _apiClient.delete('/api/v1/admin/main/fraud/blacklist/$entryId');
      } catch (_) {}
    }
  }

  Future<List<Map<String, dynamic>>> getDeviceFingerprints() async {
    try {
      final response = await _getAny(<String>[
        '$_fraudBase/device-fingerprints',
        '/api/v1/admin/main/fraud/device-fingerprints',
      ]);
      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['data']),
      );
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> verifyIdentity(String type, String value) async {
    try {
      final response = await _postAny(
        <String>['$_fraudBase/verify/$type'],
        data: <String, dynamic>{'value': value},
      );
      return _asMap(response.data);
    } catch (_) {
      return <String, dynamic>{'verified': false, 'message': 'Verification unavailable'};
    }
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
    final queryParams = <String, dynamic>{
      'skip': skip,
      'offset': skip,
      'limit': limit,
    };
    if (action != null && action != 'All') queryParams['action'] = action;
    if (severity != null && severity != 'All') queryParams['severity'] = severity;
    if (status != null && status != 'All') queryParams['status'] = status;
    if (role != null && role != 'All') queryParams['role'] = role;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
      queryParams['search'] = query;
    }

    try {
      final response = await _getAny(
        <String>[
          '$_securityBase/audit-logs',
          '$_securityBase/activity-logs',
        ],
        queryParameters: queryParams,
      );

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['logs'] ?? map['data']),
      );

      final items = rows
          .whereType<Map>()
          .map((json) => AuditLogItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      return <String, dynamic>{
        'items': items,
        'total': _toInt(map['total'] ?? map['total_count'] ?? items.length),
        'has_more': map['has_more'] == true,
      };
    } catch (_) {
      return <String, dynamic>{
        'items': <AuditLogItem>[],
        'total': 0,
        'has_more': false,
      };
    }
  }

  Future<Map<String, dynamic>> getAuditStats() async {
    try {
      final response = await _getAny(<String>[
        '$_securityBase/audit-logs/stats',
        '/api/v1/admin/main/stats',
      ]);
      return _asMap(response.data);
    } catch (_) {
      return <String, dynamic>{
        'total_today': 0,
        'admin_actions': 0,
        'critical_events': 0,
        'failed_logins': 0,
        'uptime': 'N/A',
      };
    }
  }

  Future<void> exportAuditLogs({String? action, String? module}) async {
    try {
      await _postAny(<String>['$_securityBase/audit-logs/export'], data: <String, dynamic>{
        'action': action,
        'module': module,
      });
    } catch (_) {}
  }

  Future<void> flagAuditLogSuspicious(int logId, String reason) async {
    try {
      await _patchAny(
        <String>['$_securityBase/audit-logs/$logId/flag'],
        data: <String, dynamic>{'reason': reason},
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAuditTrails() async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/audit-trails/',
        '/api/v1/admin/audit-trails',
        '$_securityBase/activity-logs',
      ]);
      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['entries'] ?? map['logs']),
      );
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  // --- Utility Methods ---

  Future<void> forceLogoutAllAdmins() async {
    try {
      await _postAny(<String>['$_securityBase/force-logout-all']);
    } catch (_) {}
  }

  Future<void> revokeAllApiTokens() async {
    try {
      await _postAny(<String>['$_securityBase/revoke-api-tokens']);
    } catch (_) {}
  }

  Future<void> saveInvestigationNote(String alertId, String content) async {
    try {
      await _postAny(<String>['$_securityBase/fraud-alerts/$alertId/notes'],
          data: <String, dynamic>{'content': content});
    } catch (_) {}
  }

  Future<void> blockUser(int userId, String reason) async {
    try {
      await _postAny(<String>['/api/v1/admin/users/$userId/ban'],
          queryParameters: <String, dynamic>{'reason': reason});
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getSecurityOriginMetrics() async {
    try {
      final response = await _getAny(<String>[
        '$_securityBase/dashboard/origins',
        '/api/v1/admin/main/monitoring/metrics',
      ]);

      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['origins'] ?? map['data']),
      );
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> getSecurityDashboard() async {
    try {
      final response = await _getAny(<String>[
        '$_securityBase/dashboard',
        '/api/v1/admin/main/stats',
      ]);
      return _asMap(response.data);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<List<Map<String, dynamic>>> getGeofences() async {
    try {
      final response = await _getAny(<String>[
        '$_iotBase/geofences',
        '/api/v1/admin/main/geofences',
      ]);
      final map = _asMap(response.data);
      final rows = _asList(
        map.isEmpty ? response.data : (map['items'] ?? map['data']),
      );
      return rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<dynamic> _getAny(
    List<String> paths, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.get(path, queryParameters: queryParameters);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for all audit endpoints');
  }

  Future<dynamic> _postAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.post(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('POST failed for all audit endpoints');
  }

  Future<dynamic> _patchAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.patch(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('PATCH failed for all audit endpoints');
  }
}

final auditRepositoryProvider =
    Provider<AuditRepository>((ref) => AuditRepository());
