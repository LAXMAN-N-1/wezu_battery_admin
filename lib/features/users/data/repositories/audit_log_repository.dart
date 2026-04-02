import 'dart:convert';

import '../../../../core/api/api_client.dart';
import '../models/audit_log.dart';

class AuditLogRepository {
  final ApiClient _api;

  AuditLogRepository([ApiClient? apiClient]) : _api = apiClient ?? ApiClient();

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeAction(String action) {
    switch (action) {
      case 'AUTH_LOGIN':
        return 'login';
      case 'AUTH_LOGOUT':
        return 'logout';
      case 'USER_CREATION':
        return 'create';
      case 'USER_INVITE':
        return 'create';
      case 'ACCOUNT_STATUS_CHANGE':
        return 'suspend';
      case 'PERMISSION_CHANGE':
        return 'permission_change';
      case 'PASSWORD_RESET':
        return 'update';
      case 'DATA_MODIFICATION':
        return 'update';
      default:
        return action.toLowerCase();
    }
  }

  String _moduleFromResource(String resourceType) {
    switch (resourceType.toUpperCase()) {
      case 'AUTH':
        return 'auth';
      case 'USER':
        return 'users';
      case 'ROLE':
      case 'RBAC':
        return 'roles';
      case 'SETTINGS':
        return 'settings';
      case 'KYC':
        return 'kyc';
      default:
        return resourceType.toLowerCase();
    }
  }

  Future<List<AuditLog>> getLogs({
    String? action,
    String? module,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await _api.get(
      '/api/v1/admin/security/audit-logs',
      queryParameters: {'days': 30, 'skip': 0, 'limit': 500},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List ? payload['items'] as List : const <dynamic>[];

    var logs = items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final normalizedAction = _normalizeAction(item['action']?.toString() ?? 'unknown');
      final moduleName = _moduleFromResource(item['resource_type']?.toString() ?? 'general');
      return AuditLog(
        id: _asInt(item['id']),
        userId: _asInt(item['user_id']),
        userName: _asInt(item['user_id']) > 0 ? 'User #${_asInt(item['user_id'])}' : 'System',
        action: normalizedAction,
        module: moduleName,
        details: item['details']?.toString() ?? '${item['action']} ${item['resource_type']}',
        ipAddress: item['ip_address']?.toString(),
        userAgent: item['user_agent']?.toString(),
        timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
        beforeValue: item['old_value'] != null ? jsonEncode(item['old_value']) : null,
        afterValue: item['new_value'] != null ? jsonEncode(item['new_value']) : null,
      );
    }).toList();

    if (action != null && action != 'all') {
      logs = logs.where((log) => log.action == action).toList();
    }
    if (module != null && module != 'all') {
      logs = logs.where((log) => log.module == module).toList();
    }
    if (userId != null) {
      logs = logs.where((log) => log.userId == userId).toList();
    }
    if (fromDate != null) {
      logs = logs.where((log) => !log.timestamp.isBefore(fromDate)).toList();
    }
    if (toDate != null) {
      logs = logs.where((log) => !log.timestamp.isAfter(toDate)).toList();
    }

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<List<String>> getActionTypes() async {
    final logs = await getLogs();
    final actions = logs.map((log) => log.action).toSet().toList()..sort();
    return ['all', ...actions];
  }

  Future<List<String>> getModules() async {
    final logs = await getLogs();
    final modules = logs.map((log) => log.module).toSet().toList()..sort();
    return ['all', ...modules];
  }
}
