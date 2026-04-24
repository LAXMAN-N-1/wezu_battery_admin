import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/services/csv/csv_service.dart';
import '../models/battery.dart';

class InventoryRepository {
  final ApiClient _api = ApiClient();
  static const String _baseUrl = '/api/v1/admin/batteries';
  static const String _altBaseUrl = '/api/v1/admin/main/batteries';

  /// Paginated battery list with total count
  Future<Map<String, dynamic>> getBatteries({
    String? status,
    String? locationType,
    String? batteryType,
    double? minHealth,
    double? maxHealth,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'offset': offset,
      'skip': offset,
      'limit': limit,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (status != null && status != 'All') {
      query['status'] = status.toLowerCase();
    }
    if (locationType != null && locationType != 'All') {
      query['location_type'] = locationType.toLowerCase();
    }
    if (batteryType != null && batteryType != 'All') {
      query['battery_type'] = batteryType;
    }
    if (minHealth != null) query['min_health'] = minHealth;
    if (maxHealth != null) query['max_health'] = maxHealth;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _getAny(<String>[_baseUrl, _altBaseUrl], query);
    final data = _asMap(response.data);

    final items = _asList(
      data.isEmpty
          ? response.data
          : (data['items'] ?? data['data'] ?? data['batteries']),
    );

    final rawTotalCount =
        data['total_count'] ?? data['total'] ?? data['count'] ?? items.length;

    return <String, dynamic>{
      'items': items
          .whereType<Map>()
          .map((json) => Battery.fromJson(Map<String, dynamic>.from(json)))
          .toList(),
      'total_count': _toInt(rawTotalCount, items.length),
    };
  }

  Future<Map<String, dynamic>> getBatterySummary() async {
    try {
      final response = await _api.get('$_baseUrl/summary');
      return _asMap(response.data);
    } catch (_) {
      final response = await _api.get('/api/v1/admin/main/stats');
      final data = _asMap(response.data);
      return <String, dynamic>{
        'total_batteries': _toInt(
          data['total_batteries'] ?? data['batteries_total'],
        ),
        'available_count': _toInt(data['available_count'] ?? data['available']),
        'rented_count': _toInt(data['rented_count'] ?? data['rented']),
        'maintenance_count': _toInt(
          data['maintenance_count'] ?? data['maintenance'],
        ),
        'retired_count': _toInt(data['retired_count'] ?? data['retired']),
        'utilization_percentage': _toDouble(
          data['utilization_percentage'] ?? data['utilization'],
        ),
      };
    }
  }

  Future<List<BatteryAuditLog>> getBatteryAuditLogs(String batteryId) async {
    final response = await _getAny(<String>[
      '$_baseUrl/$batteryId/history',
      '$_baseUrl/$batteryId/audit-logs',
    ]);
    final data = _asList(response.data);
    return data
        .whereType<Map>()
        .map((json) => BatteryAuditLog.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<List<BatteryHealthHistory>> getBatteryHealthHistory(
    String batteryId, {
    int days = 90,
  }) async {
    final response = await _getAny(
      <String>[
        '$_baseUrl/$batteryId/health-history',
        '$_baseUrl/$batteryId/snapshots',
      ],
      <String, dynamic>{'days': days},
    );
    final data = _asList(response.data);
    return data
        .whereType<Map>()
        .map(
          (json) =>
              BatteryHealthHistory.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  Future<Battery> createBattery(Map<String, dynamic> data) async {
    final payload = _normalizeBatteryPayload(data);
    final response = await _postAny(<String>[_baseUrl, _altBaseUrl], payload);
    return Battery.fromJson(_asMap(response.data));
  }

  Future<Battery> updateBattery(String id, Map<String, dynamic> data) async {
    final payload = _normalizeBatteryPayload(data);

    try {
      final response = await _api.patch('$_baseUrl/$id', data: payload);
      return Battery.fromJson(_asMap(response.data));
    } catch (_) {
      final response = await _api.put('$_altBaseUrl/$id', data: payload);
      return Battery.fromJson(_asMap(response.data));
    }
  }

  Future<void> deleteBattery(String id, {String? reason}) async {
    try {
      await _api.patch(
        '$_baseUrl/$id',
        data: <String, dynamic>{
          'status': 'retired',
          'description': reason ?? 'Admin Deletion',
        },
      );
    } catch (_) {
      await _api.delete(
        '$_baseUrl/$id',
        queryParameters: <String, dynamic>{'reason': reason},
      );
    }
  }

  Future<Map<String, dynamic>> bulkUpdateBatteries(
    List<String> batteryIds,
    String status,
  ) async {
    try {
      final response = await _api.post(
        '$_baseUrl/bulk-update',
        data: <String, dynamic>{'battery_ids': batteryIds, 'status': status},
      );
      return _asMap(response.data);
    } catch (_) {
      var updated = 0;
      for (final id in batteryIds) {
        try {
          await updateBattery(id, <String, dynamic>{'status': status});
          updated++;
        } catch (_) {}
      }

      return <String, dynamic>{
        'updated_count': updated,
        'requested_count': batteryIds.length,
      };
    }
  }

  Future<Map<String, dynamic>> importBatteries(
    List<int> bytes,
    String filename, {
    bool dryRun = false,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _postAny(
      <String>[
        '$_baseUrl/import',
        '$_baseUrl/bulk-import',
        '/api/v1/admin/users/bulk-import',
      ],
      formData,
      <String, dynamic>{'dry_run': dryRun, 'dryRun': dryRun},
    );

    return _asMap(response.data);
  }

  Future<void> exportBatteries({
    String? status,
    String? locationType,
    String? batteryType,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status != 'All') {
      query['status'] = status.toLowerCase();
    }
    if (locationType != null && locationType != 'All') {
      query['location_type'] = locationType.toLowerCase();
    }
    if (batteryType != null && batteryType != 'All') {
      query['battery_type'] = batteryType;
    }

    try {
      final response = await _api.get('$_baseUrl/export', queryParameters: query);
      await CsvService.downloadCsvString(
        response.data.toString(),
        'batteries_export',
      );
      return;
    } catch (_) {
      final result = await getBatteries(
        status: status,
        locationType: locationType,
        batteryType: batteryType,
        limit: 1000,
      );

      final batteries = result['items'] as List<Battery>;
      final buffer = StringBuffer(
        'id,serial_number,status,location_type,battery_type,health_percentage\n',
      );

      for (final b in batteries) {
        buffer.writeln(
          '${b.id},${b.serialNumber},${b.status},${b.locationType},${b.batteryType ?? ''},${b.healthPercentage.toStringAsFixed(1)}',
        );
      }

      await CsvService.downloadCsvString(buffer.toString(), 'batteries_export');
    }
  }

  Map<String, dynamic> _normalizeBatteryPayload(Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data);

    final statusRaw = payload['status']?.toString().trim().toLowerCase();
    const allowedStatus = <String>{
      'available',
      'rented',
      'maintenance',
      'retired',
      'inactive',
    };

    payload['status'] = allowedStatus.contains(statusRaw)
        ? statusRaw
        : 'available';
    payload['location_type'] =
        payload['location_type']?.toString().trim().toLowerCase() ?? 'warehouse';
    payload['health_percentage'] = _toDouble(payload['health_percentage'], 100.0);

    return payload;
  }

  Future<Response<dynamic>> _getAny(
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
    throw lastError ?? Exception('GET failed for all endpoints');
  }

  Future<Response<dynamic>> _postAny(
    List<String> paths,
    dynamic data, [
    Map<String, dynamic>? queryParameters,
  ]) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.post(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('POST failed for all endpoints');
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

  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
