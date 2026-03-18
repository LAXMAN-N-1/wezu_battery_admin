// lib/features/inventory/data/repositories/stock_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/stock.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StockRepository(apiClient);
});

class StockRepository {
  final ApiClient _api;
  final String _baseUrl = '/api/v1/admin/stock';

  StockRepository(this._api);

  Future<StockOverview> getOverview() async {
    final response = await _api.get('$_baseUrl/overview');
    return StockOverview.fromJson(response.data);
  }

  Future<List<StationStock>> getStations({bool alertOnly = false, String sortBy = 'utilization'}) async {
    final response = await _api.get('$_baseUrl/stations', queryParameters: {
      'alert_only': alertOnly,
      'sort_by': sortBy,
    });
    return (response.data as List).map((json) => StationStock.fromJson(json)).toList();
  }

  Future<List<LocationStock>> getLocations() async {
    final response = await _api.get('$_baseUrl/locations');
    return (response.data as List).map((json) => LocationStock.fromJson(json)).toList();
  }

  Future<StationStockDetail> getStationDetail(int stationId) async {
    final response = await _api.get('$_baseUrl/stations/$stationId');
    return StationStockDetail.fromJson(response.data);
  }

  Future<List<StockAlert>> getAlerts() async {
    final response = await _api.get('$_baseUrl/alerts');
    return (response.data as List).map((json) => StockAlert.fromJson(json)).toList();
  }

  Future<void> dismissAlert(int stationId, String reason) async {
    await _api.post('$_baseUrl/alerts/$stationId/dismiss', queryParameters: {'reason': reason});
  }

  Future<void> updateStationConfig(int stationId, StationStockConfig config) async {
    await _api.put('$_baseUrl/stations/$stationId/config', data: config.toJson());
  }

  Future<ReorderRequest> createReorderRequest(int stationId, int requestedQuantity, {String? reason}) async {
    final response = await _api.post('$_baseUrl/reorder', data: {
      'station_id': stationId,
      'requested_quantity': requestedQuantity,
      'reason': reason,
    });
    return ReorderRequest.fromJson(response.data);
  }
}
