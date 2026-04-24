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
    final params = <String, dynamic>{
      'skip': skip,
      'offset': skip,
      'limit': limit,
    };
    if (actionType != null && actionType.isNotEmpty) {
      params['action_type'] = actionType;
      params['action'] = actionType;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
      params['q'] = search;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      params['date_from'] = dateFrom;
      params['start_date'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      params['date_to'] = dateTo;
      params['end_date'] = dateTo;
    }

    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/audit-trails/',
        '/api/v1/admin/audit-trails',
        '/api/v1/admin/security/activity-logs',
      ], params);

      final map = _asMap(response.data);
      final list = _asList(
        map.isEmpty
            ? response.data
            : (map['entries'] ?? map['items'] ?? map['logs'] ?? map['data']),
      );

      final entries = list
          .whereType<Map>()
          .map((e) => AuditTrailEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final total = _toInt(
        map['total_count'] ?? map['total'] ?? map['count'] ?? entries.length,
        entries.length,
      );

      return <String, dynamic>{'entries': entries, 'total_count': total};
    } catch (_) {
      return <String, dynamic>{
        'entries': <AuditTrailEntry>[],
        'total_count': 0,
      };
    }
  }

  Future<AuditTrailStats> getStats() async {
    try {
      final response = await _getAny(<String>[
        '/api/v1/admin/audit-trails/stats',
        '/api/v1/admin/audit-trails/summary',
      ]);
      return AuditTrailStats.fromJson(_asMap(response.data));
    } catch (_) {
      // Fallback: derive basic stats from latest entries endpoint if dedicated stats is unavailable.
      try {
        final response = await _getAny(<String>[
          '/api/v1/admin/audit-trails/',
          '/api/v1/admin/security/activity-logs',
        ], <String, dynamic>{'skip': 0, 'limit': 200});
        final map = _asMap(response.data);
        final list = _asList(
          map.isEmpty
              ? response.data
              : (map['entries'] ?? map['items'] ?? map['logs']),
        );

        final entries = list
            .whereType<Map>()
            .map((e) => AuditTrailEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

        final todayCount = entries
            .where((e) => e.timestamp.isAfter(startOfToday))
            .length;
        final weekCount = entries
            .where((e) => e.timestamp.isAfter(startOfWeek))
            .length;

        return AuditTrailStats(
          totalEntries: entries.length,
          todayCount: todayCount,
          weekCount: weekCount,
          transfers: entries.where((e) => e.actionType == 'transfer').length,
          disposals: entries.where((e) => e.actionType == 'disposal').length,
          statusChanges: entries
              .where((e) => e.actionType == 'status_change')
              .length,
          manualEntries: entries
              .where((e) => e.actionType == 'manual_entry')
              .length,
        );
      } catch (_) {
        return AuditTrailStats(
          totalEntries: 0,
          todayCount: 0,
          weekCount: 0,
          transfers: 0,
          disposals: 0,
          statusChanges: 0,
          manualEntries: 0,
        );
      }
    }
  }

  Future<dynamic> _getAny(
    List<String> paths, [
    Map<String, dynamic>? queryParameters,
  ]) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.get(path, queryParameters: queryParameters);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for all audit-trail endpoints');
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

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
