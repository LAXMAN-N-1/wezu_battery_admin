import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/csv/csv_service.dart';
import '../models/battery.dart';

class InventoryRepository {
  final ApiClient _api;
  InventoryRepository([ApiClient? api]) : _api = api ?? ApiClient();
  static const String _baseUrl = '/api/v1/admin/batteries';

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
    final Map<String, dynamic> query = {
      'offset': offset,
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

    final response = await _api.get(_baseUrl, queryParameters: query);
    final data = response.data;
    final List<dynamic> items = data['items'] ?? [];
    final rawTotalCount = data['total_count'];
    final totalCount = (rawTotalCount is num)
        ? rawTotalCount.toInt()
        : int.tryParse(rawTotalCount?.toString() ?? '') ?? 0;
    return {
      'items': items.map((json) => Battery.fromJson(json)).toList(),
      'total_count': totalCount,
    };
  }

  Future<Map<String, dynamic>> getBatterySummary() async {
    final response = await _api.get('$_baseUrl/summary');
    return response.data;
  }

  Future<List<BatteryAuditLog>> getBatteryAuditLogs(String batteryId) async {
    final response = await _api.get('$_baseUrl/$batteryId/history');
    final List<dynamic> data = response.data;
    return data.map((json) => BatteryAuditLog.fromJson(json)).toList();
  }

  Future<List<BatteryHealthHistory>> getBatteryHealthHistory(
    String batteryId, {
    int days = 90,
  }) async {
    final response = await _api.get(
      '$_baseUrl/$batteryId/health-history',
      queryParameters: {'days': days},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => BatteryHealthHistory.fromJson(json)).toList();
  }

  Future<Battery> createBattery(Map<String, dynamic> data) async {
    final response = await _api.post(_baseUrl, data: data);
    return Battery.fromJson(response.data);
  }

  Future<Battery> updateBattery(String id, Map<String, dynamic> data) async {
    final response = await _api.patch('$_baseUrl/$id', data: data);
    return Battery.fromJson(response.data);
  }

  Future<void> deleteBattery(String id, {String? reason}) async {
    await _api.patch(
      '$_baseUrl/$id',
      data: {'status': 'retired', 'description': reason ?? 'Admin Deletion'},
    );
  }

  Future<Map<String, dynamic>> bulkUpdateBatteries(
    List<String> batteryIds,
    String status,
  ) async {
    final response = await _api.post(
      '$_baseUrl/bulk-update',
      data: {'battery_ids': batteryIds.map(int.parse).toList(), 'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> importBatteries(
    List<int> bytes,
    String filename, {
    bool dryRun = false,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _api.post(
      '$_baseUrl/import',
      data: formData,
      queryParameters: {'dry_run': dryRun},
    );
    return response.data;
  }

  Future<void> exportBatteries({
    String? status,
    String? locationType,
    String? batteryType,
  }) async {
    final Map<String, dynamic> query = {};
    if (status != null && status != 'All') {
      query['status'] = status.toLowerCase();
    }
    if (locationType != null && locationType != 'All') {
      query['location_type'] = locationType.toLowerCase();
    }
    if (batteryType != null && batteryType != 'All') {
      query['battery_type'] = batteryType;
    }

    final response = await _api.get('$_baseUrl/export', queryParameters: query);

    await CsvService.downloadCsvString(
      response.data.toString(),
      'batteries_export',
    );
  }
}
