import '../../../../core/api/api_client.dart';
import '../models/battery_catalog.dart';

class BatteryCatalogRepository {
  final ApiClient _api;
  BatteryCatalogRepository([ApiClient? api]) : _api = api ?? ApiClient();

  static const String _specBase = '/api/v1/batteries/specs';
  static const String _batchBase = '/api/v1/batteries/batches';

  Future<List<BatterySpecModel>> listSpecs() async {
    final response = await _api.get(_specBase);
    final payload = response.data;

    final List<dynamic> rows;
    if (payload is List) {
      rows = payload;
    } else if (payload is Map<String, dynamic> && payload['items'] is List) {
      rows = payload['items'] as List<dynamic>;
    } else {
      rows = const [];
    }

    return rows
        .whereType<Map>()
        .map((raw) => BatterySpecModel.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<BatterySpecModel> getSpec(int specId) async {
    final response = await _api.get('$_specBase/$specId');
    return BatterySpecModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<BatterySpecModel> createSpec(Map<String, dynamic> data) async {
    final response = await _api.post(_specBase, data: data);
    return BatterySpecModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<BatterySpecModel> updateSpec(
    int specId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.patch('$_specBase/$specId', data: data);
    return BatterySpecModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<BatterySpecModel> setDefaultSpec(int specId) async {
    final response = await _api.patch('$_specBase/$specId/set-default');
    return BatterySpecModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Map<String, dynamic>> backfillDefault({int? specId}) async {
    final payload = <String, dynamic>{};
    if (specId != null) {
      payload['spec_id'] = specId;
    }
    final response = await _api.post(
      '$_specBase/backfill-default',
      data: payload,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<BatteryBatchModel> createBatch(Map<String, dynamic> data) async {
    final response = await _api.post(_batchBase, data: data);
    return BatteryBatchModel.fromJson(Map<String, dynamic>.from(response.data));
  }
}
