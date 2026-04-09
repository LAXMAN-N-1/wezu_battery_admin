import '../../../../core/api/api_client.dart';
import '../models/audit_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditRepository {
  final ApiClient _apiClient;
  AuditRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _securityBase = '/api/v1/admin/security';
  static const String _fraudBase = '/api/v1/admin/fraud';
  static const String _auditBase = '/api/v1/admin/audit-trails';

  // In-memory mock storage for settings persistence in demo/API-fail mode
  static Map<String, dynamic>? _mockSettings;

  Future<Map<String, dynamic>> getAuditLogs({
    String? action,
    String? resourceType,
    String? severity,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
    int? userId,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      // First try /api/v1/admin/security/audit-logs
      final r = await _apiClient.get('$_securityBase/audit-logs', queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (action != null) 'action': action,
        if (resourceType != null) 'resource_type': resourceType,
        if (severity != null) 'severity': severity,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (userId != null) 'user_id': userId.toString(),
      });
      
      final data = r.data is Map ? Map<String, dynamic>.from(r.data) : <String, dynamic>{};
      final itemsRaw = data['items'] ?? data['logs']; // Handle both 'items' and 'logs'
      final List<dynamic> itemsList = itemsRaw is List ? itemsRaw : [];
      
      return {
        'items': itemsList.map((e) => AuditLogItem.fromJson(e is Map ? Map<String, dynamic>.from(e) : {})).toList(),
        'total_count': data['total_count'] ?? data['total'] ?? 0,
      };
    } catch (e) {
      // Fallback to /api/v1/admin/audit-trails if security endpoint fails
      try {
        final r = await _apiClient.get('$_auditBase/', queryParameters: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        });
        final data = r.data is Map ? Map<String, dynamic>.from(r.data) : <String, dynamic>{};
        final itemsRaw = data['items'] ?? data['logs'];
        final List<dynamic> itemsList = itemsRaw is List ? itemsRaw : [];
        return {
          'items': itemsList.map((e) => AuditLogItem.fromJson(e is Map ? Map<String, dynamic>.from(e) : {})).toList(),
          'total_count': data['total_count'] ?? data['total'] ?? 0,
        };
      } catch (_) {
        return _getDemoAuditLogs(skip, limit, status, severity);
      }
    }
  }

  Future<Map<String, dynamic>> getAuditStats() async {
    try {
      // Try both possible stats locations
      final r = await _apiClient.get('$_securityBase/audit-logs/stats');
      return r.data is Map ? Map<String, dynamic>.from(r.data) : {};
    } catch (e) {
      try {
        final r = await _apiClient.get('$_auditBase/stats');
        return r.data is Map ? Map<String, dynamic>.from(r.data) : {};
      } catch (_) {
        return {
          'total': 1240,
          'info': 850,
          'warning': 320,
          'critical': 70,
        };
      }
    }
  }

  Future<Map<String, dynamic>> getSecurityEvents({
    String? severity,
    String? eventType,
    bool? isResolved,
    int skip = 0,
  }) async {
    try {
      final r = await _apiClient.get('$_securityBase/security-events', queryParameters: {
        'skip': skip.toString(),
        if (severity != null) 'severity': severity,
        if (eventType != null) 'event_type': eventType,
        if (isResolved != null) 'is_resolved': isResolved.toString(),
      });
      
      final data = r.data is Map ? r.data : {};
      return {
        'items': (data['items'] as List? ?? []).map((e) => SecurityEventItem.fromJson(e)).toList(),
        'total_count': data['total_count'] ?? data['total'] ?? 0,
      };
    } catch (e) {
      return _getDemoSecurityEvents(skip);
    }
  }

  Future<void> resolveSecurityEvent(int eventId) async {
    await _apiClient.patch('$_securityBase/security-events/$eventId/resolve');
  }

  Future<Map<String, dynamic>> getFraudAlerts({String? status, int skip = 0}) async {
    try {
      final r = await _apiClient.get('$_securityBase/fraud-alerts', queryParameters: {
        'skip': skip.toString(),
        if (status != null) 'status': status,
      });
      
      final data = r.data is Map ? r.data : {};
      return {
        'items': (data['items'] as List? ?? []).map((e) => FraudAlertItem.fromJson(e)).toList(),
        'total_count': data['total_count'] ?? data['total'] ?? 0,
      };
    } catch (e) {
      return _getDemoFraudAlerts();
    }
  }

  Future<Map<String, dynamic>> getHighRiskUsers({int skip = 0}) async {
    try {
      final r = await _apiClient.get('$_fraudBase/high-risk-users', queryParameters: {
        'skip': skip.toString(),
      });
      final data = r.data is Map ? r.data : {};
      return {
        'items': data['items'] ?? [],
        'total_count': data['total_count'] ?? data['total'] ?? 0,
      };
    } catch (e) {
      return {'items': [], 'total_count': 0};
    }
  }

  Future<Map<String, dynamic>> getDuplicateAccounts({int skip = 0}) async {
    try {
      final r = await _apiClient.get('$_fraudBase/duplicate-accounts', queryParameters: {
        'skip': skip.toString(),
      });
      final data = r.data is Map ? r.data : {};
      return {
        'items': data['items'] ?? [],
        'total_count': data['total_count'] ?? data['total'] ?? 0,
      };
    } catch (e) {
      return {'items': [], 'total_count': 0};
    }
  }

  Future<Map<String, dynamic>> getBlacklist({int skip = 0}) async {
    try {
      final r = await _apiClient.get('$_fraudBase/blacklist', queryParameters: {
        'skip': skip.toString(),
      });
      final data = r.data is Map ? r.data : {};
      return {
        'items': data['items'] ?? [],
        'total_count': data['total_count'] ?? data['total'] ?? 0,
      };
    } catch (e) {
      return {'items': [], 'total_count': 0};
    }
  }

  Future<void> addToBlacklist(Map<String, dynamic> data) async {
    await _apiClient.post('$_fraudBase/blacklist', data: data);
  }

  Future<void> removeFromBlacklist(String id) async {
    await _apiClient.delete('$_fraudBase/blacklist/$id');
  }

  Future<void> updateFraudAlertStatus(String id, String status) async {
    await _apiClient.patch('$_securityBase/fraud-alerts/$id/status', data: {'status': status});
  }

  Future<void> escalateFraudAlert(String id) async {
    await _apiClient.post('$_securityBase/fraud-alerts/$id/escalate');
  }

  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      final r = await _apiClient.get('$_securityBase/security-settings');
      return r.data is Map ? Map<String, dynamic>.from(r.data) : {};
    } catch (e) {
      return _mockSettings ?? _getDemoSecuritySettings();
    }
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> updates) async {
    try {
      await _apiClient.patch('$_securityBase/security-settings', data: updates);
    } catch (_) {
      // Demo mode / mock success - update local mock storage
      final current = _mockSettings ?? _getDemoSecuritySettings();
      _mockSettings = {...current, ...updates};
      await Future.delayed(const Duration(seconds: 1));
      return;
    }
  }

  Future<AuditDashboardStats> getAuditDashboardStats({String range = '24h'}) async {
    try {
      final r = await _apiClient.get('$_securityBase/dashboard', queryParameters: {'range': range});
      final data = r.data is Map ? Map<String, dynamic>.from(r.data) : <String, dynamic>{};
      
      final activityRaw = data['activity_over_time'];
      final List<dynamic> activityList = activityRaw is List ? activityRaw : [];
      
      final recentRaw = data['recent_critical'];
      final List<dynamic> recentList = recentRaw is List ? recentRaw : [];

      return AuditDashboardStats(
        totalEventsToday: data['total_events'] ?? 0,
        adminActionsToday: data['admin_actions'] ?? 0,
        infoEventsToday: data['info_events'] ?? 0,
        warningEventsToday: data['warning_events'] ?? 0,
        criticalEventsToday: data['critical_events'] ?? 0,
        failedLoginsToday: data['failed_logins'] ?? 0,
        activityPoints: activityList.map((e) => ChartPoint(
          time: e['time']?.toString() ?? '',
          apiRequests: e['requests'] ?? 0,
          failedLogins: e['failed'] ?? 0,
        )).toList(),
        categoryDistribution: Map<String, dynamic>.from(data['categories'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
        recentCriticalEvents: recentList.map((e) => SecurityEventItem.fromJson(e is Map ? Map<String, dynamic>.from(e) : {})).toList(),
        topLocations: (data['locations'] as List? ?? []).map((e) => LocationStat(
          country: e['country']?.toString() ?? '',
          attempts: e['attempts']?.toString() ?? '0',
          successfulAttempts: e['successful']?.toString() ?? '0',
          successRate: e['rate']?.toString() ?? '0%',
        )).toList(),
      );
    } catch (e) {
      return _getDemoDashboardStats(range);
    }
  }

  Future<String> exportAuditLogs({
    String format = 'csv',
    String? action,
    String? severity,
  }) async {
    try {
      final r = await _apiClient.post('$_securityBase/audit-logs/export', data: {
        'format': format,
        if (action != null) 'action': action,
        if (severity != null) 'severity': severity,
      });
      return r.data['download_url'] ?? '';
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
      return 'https://example.com/mock-export-${DateTime.now().millisecondsSinceEpoch}.$format';
    }
  }

  Future<String> exportSecurityEvents({String format = 'csv'}) async {
    try {
      final r = await _apiClient.post('$_securityBase/security-events/export', data: {'format': format});
      return r.data['download_url'] ?? '';
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
      return 'https://example.com/mock-security-export-${DateTime.now().millisecondsSinceEpoch}.$format';
    }
  }

  Future<void> flagAuditLogSuspicious(int logId, {bool isSuspicious = true}) async {
    await _apiClient.patch('$_securityBase/audit-logs/$logId/flag', data: {'is_suspicious': isSuspicious});
  }

  // --- Demo Fallbacks ---

  Map<String, dynamic> _getDemoAuditLogs(int skip, int limit, [String? status, String? severity]) {
    final now = DateTime.now();
    List<AuditLogItem> items = [];
    int counter = 0;
    int itemsSkipped = 0;
    
    // We iterate until we find enough items to cover the 'skip' and then fill up to 'limit'
    while (items.length < limit && counter < 2000) {
      final logId = counter + 1;
      final logSeverity = counter % 15 == 0 ? 'critical' : (counter % 7 == 0 ? 'warning' : 'info');
      final logStatus = counter % 5 == 0 ? 'failed' : 'success';
      
      bool matchesSeverity = severity == null || logSeverity.toLowerCase() == severity.toLowerCase();
      bool matchesStatus = status == null || logStatus.toLowerCase() == status.toLowerCase();
      
      if (matchesSeverity && matchesStatus) {
        if (itemsSkipped >= skip) {
          items.add(AuditLogItem(
            id: logId,
            userName: counter % 4 == 0 ? 'Laxman N' : (counter % 3 == 0 ? 'Admin User' : 'System'),
            userEmail: counter % 4 == 0 ? 'laxman@wezu.auto' : 'system@wezu.auto',
            userRole: counter % 4 == 0 ? 'Super Admin' : (counter % 3 == 0 ? 'Editor' : 'System'),
            action: _getDemoAction(counter),
            module: _getDemoModule(counter),
            resourceType: counter % 2 == 0 ? 'User' : 'Settings',
            resourceId: 'RES-${1000 + counter}',
            details: 'Detailed action performed on resource #${1000 + counter}',
            timestamp: now.subtract(Duration(minutes: counter * 5)).toIso8601String(),
            severity: logSeverity,
            status: logStatus,
            ipAddress: '192.168.1.${(10 + counter) % 255}',
            city: counter % 3 == 0 ? 'Hyderabad' : (counter % 2 == 0 ? 'Bangalore' : 'Delhi'),
            countryFlag: '🇮🇳',
            userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
            browser: 'Chrome',
            os: 'macOS',
            oldValue: '{"status": "active", "version": ${counter % 5}}',
            newValue: '{"status": "${logStatus == 'success' ? 'active' : 'locked'}", "version": ${counter % 5 + 1}}',
          ));
        }
        itemsSkipped++;
      }
      counter++;
    }
    
    return {
      'items': items,
      'total_count': 1240,
    };
  }

  String _getDemoAction(int i) {
    const actions = ['LOGIN_SUCCESS', 'UPDATE_USER', 'DELETE_RECORD', 'ACCESS_DENIED', 'PASSWORD_RESET', 'SETTINGS_CHANGED', 'EXPORT_DATA'];
    return actions[i % actions.length];
  }

  String _getDemoModule(int i) {
    const modules = ['AUTH', 'CMS', 'FINANCE', 'SECURITY', 'FLEET'];
    return modules[i % modules.length];
  }

  Map<String, dynamic> _getDemoSecurityEvents(int skip) {
    final now = DateTime.now();
    return {
      'items': [
        SecurityEventItem(
          id: 1, eventType: 'Brute Force Attempt', severity: 'high',
          details: 'Multiple failed logins from IP 192.168.1.50',
          sourceIp: '192.168.1.50', country: 'United States', countryFlag: '🇺🇸',
          timestamp: now.subtract(const Duration(minutes: 5)).toIso8601String(),
          isResolved: false,
        ),
        SecurityEventItem(
          id: 2, eventType: 'Suspicious IP Access', severity: 'medium',
          details: 'Access attempt from known malicious IP range',
          sourceIp: '45.12.8.22', country: 'North Korea', countryFlag: '🇰🇵',
          timestamp: now.subtract(const Duration(hours: 1)).toIso8601String(),
          isResolved: false,
        ),
        SecurityEventItem(
          id: 3, eventType: 'Elevated Privileges Granted', severity: 'low',
          details: 'User #102 assigned Super Admin role',
          sourceIp: '10.0.0.5', country: 'India', countryFlag: '🇮🇳',
          timestamp: now.subtract(const Duration(hours: 3)).toIso8601String(),
          isResolved: true,
        ),
      ],
      'total_count': 3,
    };
  }

  Map<String, dynamic> _getDemoFraudAlerts() {
    return {
      'items': [
        FraudAlertItem(
          id: 'FD-2026-001', userId: 102, userName: 'Alex River',
          userAvatar: '', userEmail: 'alex@example.com',
          alertType: 'Suspicious Login', riskScore: 85,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          status: 'Open', details: 'Login attempt from unauthorized country (North Korea).',
        ),
        FraudAlertItem(
          id: 'FD-2026-002', userId: 505, userName: 'John Doe',
          userAvatar: '', userEmail: 'john@example.com',
          alertType: 'Multi-Device Login', riskScore: 62,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          status: 'Investigation', details: 'User logged in from 5 different devices.',
        ),
      ],
      'total_count': 2,
    };
  }

  Map<String, dynamic> _getDemoSecuritySettings() {
    return {
      'min_password_length': 12,
      'req_uppercase': true,
      'req_number': true,
      'req_special': false,
      'password_expiry': 'Every 90 Days',
      'reuse_limit': 5,
      '2fa_super_admin': true,
      '2fa_all_admin': false,
      '2fa_dealers': false,
      '2fa_sms': true,
      '2fa_email': true,
      '2fa_totp': false,
      '2fa_grace': '7 Days',
      'session_timeout': '30 minutes',
      'max_sessions': 3,
      'remember_me_days': '30 Days',
      'ip_whitelist_enabled': true,
      'ip_whitelist': [
        {'ip': '192.168.1.1', 'label': 'Main Office', 'added_by': 'Admin', 'date': 'Jan 10, 2026'},
        {'ip': '10.0.0.1', 'label': 'VPN Gateway', 'added_by': 'Admin', 'date': 'Feb 15, 2026'},
      ],
      'max_failed_attempts': 5,
      'lockout_duration': '15 minutes',
      'captcha_mode': 'After 3 Failed Attempts',
      'alert_suspicious': true,
      'alert_new_device': true,
    };
  }

  AuditDashboardStats _getDemoDashboardStats(String range) {
    final is7d = range == '7d';
    final pointsCount = is7d ? 7 : 12;
    
    return AuditDashboardStats(
      totalEventsToday: is7d ? 8500 : 1240,
      adminActionsToday: is7d ? 320 : 45,
      infoEventsToday: is7d ? 1200 : 150,
      warningEventsToday: is7d ? 180 : 24,
      criticalEventsToday: is7d ? 15 : 3,
      failedLoginsToday: is7d ? 85 : 12,
      activityPoints: List.generate(pointsCount, (i) {
        final hour = i * 2;
        final time = is7d ? 'Apr ${i + 1}' : '${hour.toString().padLeft(2, '0')}:00';
        return ChartPoint(
          time: time,
          apiRequests: 50 + (i * 15) + (is7d ? 200 : 0) + (i % 3 == 0 ? 40 : 0),
          failedLogins: i % 5 == 0 ? (is7d ? 12 : 6) : (i % 3 == 0 ? 3 : 1),
        );
      }),
      categoryDistribution: {
        'Auth Events': 42.5,
        'Data Changes': 28.0,
        'System Events': 18.5,
        'Security Threats': 11.0,
      },
      recentCriticalEvents: List.generate(5, (i) => SecurityEventItem(
        id: 100 + i,
        eventType: i % 2 == 0 ? 'Brute Force Attempt' : 'SQL Injection Detected',
        severity: 'high',
        details: i % 2 == 0 
          ? 'Multiple failed logins from IP 192.168.1.${50 + i}' 
          : 'Malicious pattern detected in /api/v1/users endpoint',
        sourceIp: '192.168.1.${50 + i}',
        country: i % 2 == 0 ? 'United States' : 'Russia',
        countryFlag: i % 2 == 0 ? '🇺🇸' : '🇷🇺',
        timestamp: DateTime.now().subtract(Duration(minutes: 5 + (i * 12))).toIso8601String(),
        isResolved: false,
      )),
      topLocations: [
        LocationStat(country: 'United States', attempts: '450', successfulAttempts: '441', successRate: '98%'),
        LocationStat(country: 'Germany', attempts: '120', successfulAttempts: '110', successRate: '92%'),
        LocationStat(country: 'India', attempts: '85', successfulAttempts: '81', successRate: '95%'),
        LocationStat(country: 'China', attempts: '64', successfulAttempts: '8', successRate: '12%'),
        LocationStat(country: 'Russia', attempts: '42', successfulAttempts: '3', successRate: '8%'),
      ],
    );
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) => AuditRepository());
