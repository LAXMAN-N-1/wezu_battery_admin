import '../../../../core/api/api_client.dart';
import '../models/bess_models.dart';

class BessRepository {
  final ApiClient _apiClient;
  BessRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/bess';

  Future<BessOverviewStats> getOverview() async {
    try {
      final response = await _getAny(<String>[
        '$_base/overview',
        '/api/v1/admin/main/stats',
      ]);
      return BessOverviewStats.fromJson(_asMap(response.data));
    } catch (_) {
      return BessOverviewStats.fromJson(const <String, dynamic>{});
    }
  }

  Future<List<BessUnit>> getUnits({String? status}) async {
    try {
      final response = await _getAny(
        <String>[
          '$_base/units',
          '/api/v1/admin/main/iot/stations/status',
          '/api/v1/admin/main/stations',
        ],
        queryParameters: <String, dynamic>{
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final items = _extractList(response.data, keys: const <String>[
        'units',
        'items',
        'stations',
        'data',
      ]);

      return items
          .whereType<Map>()
          .map((e) => BessUnit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <BessUnit>[];
    }
  }

  Future<List<BessEnergyLog>> getEnergyLogs({
    int? bessUnitId,
    int hours = 24,
  }) async {
    try {
      final response = await _getAny(
        <String>[
          '$_base/energy-logs',
          if (bessUnitId != null)
            '/api/v1/admin/main/iot/telematics/$bessUnitId',
        ],
        queryParameters: <String, dynamic>{
          'hours': hours,
          if (bessUnitId != null) 'bess_unit_id': bessUnitId,
        },
      );

      final items = _extractList(response.data, keys: const <String>[
        'logs',
        'items',
        'data',
        'telematics',
      ]);

      return items
          .whereType<Map>()
          .map((e) => BessEnergyLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <BessEnergyLog>[];
    }
  }

  Future<List<Map<String, dynamic>>> getEnergySummary({int days = 7}) async {
    try {
      final response = await _getAny(
        <String>['$_base/energy-logs/summary'],
        queryParameters: <String, dynamic>{'days': days},
      );
      final items = _extractList(response.data, keys: const <String>[
        'summary',
        'items',
        'data',
      ]);
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      // Derive a simple summary from recent logs when summary endpoint is missing.
      final logs = await getEnergyLogs(hours: days * 24);
      if (logs.isEmpty) return <Map<String, dynamic>>[];

      final byDate = <String, Map<String, dynamic>>{};
      for (final log in logs) {
        final date = log.timestamp.length >= 10
            ? log.timestamp.substring(0, 10)
            : log.timestamp;
        final row = byDate.putIfAbsent(
          date,
          () => <String, dynamic>{'date': date, 'charged': 0.0, 'discharged': 0.0},
        );
        if (log.powerKw >= 0) {
          row['charged'] = (row['charged'] as double) + log.energyKwh;
        } else {
          row['discharged'] = (row['discharged'] as double) + log.energyKwh;
        }
      }

      final sorted = byDate.values.toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return sorted;
    }
  }

  Future<List<BessGridEvent>> getGridEvents({
    int? bessUnitId,
    String? eventType,
    int days = 30,
  }) async {
    try {
      final response = await _getAny(
        <String>['$_base/grid-events'],
        queryParameters: <String, dynamic>{
          'days': days,
          if (bessUnitId != null) 'bess_unit_id': bessUnitId,
          if (eventType != null && eventType.isNotEmpty) 'event_type': eventType,
        },
      );

      final items = _extractList(response.data, keys: const <String>[
        'events',
        'items',
        'data',
      ]);

      return items
          .whereType<Map>()
          .map((e) => BessGridEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <BessGridEvent>[];
    }
  }

  Future<List<BessReport>> getReports({String? reportType, int? bessUnitId}) async {
    try {
      final response = await _getAny(
        <String>['$_base/reports'],
        queryParameters: <String, dynamic>{
          if (reportType != null && reportType.isNotEmpty)
            'report_type': reportType,
          if (bessUnitId != null) 'bess_unit_id': bessUnitId,
        },
      );

      final items = _extractList(response.data, keys: const <String>[
        'reports',
        'items',
        'data',
      ]);

      return items
          .whereType<Map>()
          .map((e) => BessReport.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <BessReport>[];
    }
  }

  Future<Map<String, dynamic>> getReportsKpi() async {
    try {
      final response = await _getAny(<String>['$_base/reports/kpi']);
      return _asMap(response.data);
    } catch (_) {
      final reports = await getReports();
      double totalCharged = 0;
      double totalDischarged = 0;
      double totalRevenue = 0;
      double totalCost = 0;
      double avgEfficiency = 0;

      for (final report in reports) {
        totalCharged += report.totalChargedKwh;
        totalDischarged += report.totalDischargedKwh;
        totalRevenue += report.revenue;
        totalCost += report.cost;
        avgEfficiency += report.avgEfficiency;
      }

      if (reports.isNotEmpty) {
        avgEfficiency = avgEfficiency / reports.length;
      }

      return <String, dynamic>{
        'total_charged': totalCharged,
        'total_discharged': totalDischarged,
        'avg_efficiency': avgEfficiency,
        'total_revenue': totalRevenue,
        'total_cost': totalCost,
      };
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
    throw lastError ?? Exception('GET failed for all BESS endpoints');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic value, {List<String> keys = const []}) {
    if (value is List) return value;

    final map = _asMap(value);
    for (final key in keys) {
      final item = map[key];
      if (item is List) return item;
    }

    if (map['data'] is List) return map['data'] as List;
    return const <dynamic>[];
  }
}
