// lib/features/inventory/data/repositories/stock_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_cache.dart';
import '../models/stock.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StockRepository(apiClient);
});

class StockRepository {
  final ApiClient _api;
  final String _baseUrl = '/api/v1/admin/stock';
  final ApiCache _cache = ApiCache();

  StockRepository(this._api);

  Future<StockOverview> getOverview() async {
    return _cache.getOrFetch<StockOverview>(
      'stock_overview',
      ttl: const Duration(seconds: 60),
      fetch: () async {
        final response = await _api.get('$_baseUrl/overview');
        return StockOverview.fromJson(response.data);
      },
    );
  }

  Future<List<StationStock>> getStations({bool alertOnly = false, String sortBy = 'utilization'}) async {
    return _cache.getOrFetch<List<StationStock>>(
      'stock_stations_${alertOnly}_$sortBy',
      ttl: const Duration(seconds: 30),
      fetch: () async {
        final response = await _api.get('$_baseUrl/stations', queryParameters: {
          'alert_only': alertOnly,
          'sort_by': sortBy,
        });
        return (response.data as List).map((json) => StationStock.fromJson(json)).toList();
      },
    );
  }

  Future<List<LocationStock>> getLocations() async {
    return _cache.getOrFetch<List<LocationStock>>(
      'stock_locations',
      ttl: const Duration(seconds: 60),
      fetch: () async {
        final response = await _api.get('$_baseUrl/locations');
        return (response.data as List).map((json) => LocationStock.fromJson(json)).toList();
      },
    );
  }

  Future<StationStockDetail> getStationDetail(int stationId) async {
    return _cache.getOrFetch<StationStockDetail>(
      'stock_station_$stationId',
      ttl: const Duration(seconds: 30),
      fetch: () async {
        final response = await _api.get('$_baseUrl/stations/$stationId');
        return StationStockDetail.fromJson(response.data);
      },
    );
  }

  Future<List<StockAlert>> getAlerts() async {
    return _cache.getOrFetch<List<StockAlert>>(
      'stock_alerts',
      ttl: const Duration(seconds: 30),
      fetch: () async {
        final response = await _api.get('$_baseUrl/alerts');
        return (response.data as List).map((json) => StockAlert.fromJson(json)).toList();
      },
    );
  }

  Future<void> dismissAlert(int stationId, String reason) async {
    await _api.post('$_baseUrl/alerts/$stationId/dismiss', queryParameters: {'reason': reason});
    // Invalidate alerts cache after mutation
    _cache.invalidatePrefix('stock_alerts');
  }

  Future<void> updateStationConfig(int stationId, StationStockConfig config) async {
    await _api.put('$_baseUrl/stations/$stationId/config', data: config.toJson());
    // Invalidate station cache after mutation
    _cache.invalidate('stock_station_$stationId');
    _cache.invalidatePrefix('stock_stations');
  }

  Future<ReorderRequest> createReorderRequest(int stationId, int requestedQuantity, {String? reason}) async {
    final response = await _api.post('$_baseUrl/reorder', data: {
      'station_id': stationId,
      'requested_quantity': requestedQuantity,
      'reason': reason,
    });
    // Invalidate overview/stations cache after reorder
    _cache.invalidatePrefix('stock_');
    return ReorderRequest.fromJson(response.data);
  }
}
