// lib/features/inventory/data/repositories/stock_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/stock.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StockRepository(apiClient);
});

class StockRepository {
  final ApiClient _api;
  static const String _baseUrl = '/api/v1/admin/stock';
  static const String _altBaseUrl = '/api/v1/admin/inventory/stock';

  StockRepository(this._api);

  Future<StockOverview> getOverview() async {
    final response = await _getAny(<String>[
      '$_baseUrl/overview',
      '$_altBaseUrl/overview',
      '/api/v1/admin/inventory/overview',
      '/api/v1/admin/main/stats',
    ]);
    final data = _extractMap(response.data);
    return StockOverview.fromJson(data);
  }

  Future<List<StationStock>> getStations({
    bool alertOnly = false,
    String sortBy = 'utilization',
  }) async {
    final response = await _getAny(
      <String>[
        '$_baseUrl/stations',
        '$_altBaseUrl/stations',
        '/api/v1/admin/inventory/stations',
        '/api/v1/admin/main/stations',
      ],
      queryParameters: <String, dynamic>{
        'alert_only': alertOnly,
        'sort_by': sortBy,
      },
    );

    final rawItems = _extractList(response.data, keys: <String>[
      'stations',
      'items',
      'data',
    ]);

    var stations = rawItems
        .whereType<Map>()
        .map((json) => StationStock.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    if (alertOnly) {
      stations = stations.where((s) => s.isLowStock).toList();
    }

    switch (sortBy) {
      case 'available':
        stations.sort((a, b) => a.availableCount.compareTo(b.availableCount));
        break;
      case 'name':
        stations.sort((a, b) => a.stationName.compareTo(b.stationName));
        break;
      case 'utilization':
      default:
        stations.sort(
          (a, b) => b.utilizationPercentage.compareTo(a.utilizationPercentage),
        );
    }

    return stations;
  }

  Future<List<LocationStock>> getLocations() async {
    final response = await _getAny(<String>[
      '$_baseUrl/locations',
      '$_altBaseUrl/locations',
      '/api/v1/admin/inventory/locations',
    ]);
    final rawItems = _extractList(response.data, keys: <String>[
      'locations',
      'items',
      'data',
    ]);
    return rawItems
        .whereType<Map>()
        .map((json) => LocationStock.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<StationStockDetail> getStationDetail(int stationId) async {
    final response = await _getAny(<String>[
      '$_baseUrl/stations/$stationId',
      '$_altBaseUrl/stations/$stationId',
      '/api/v1/admin/inventory/stations/$stationId',
      '/api/v1/admin/main/stations/$stationId',
    ]);

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('station') || raw.containsKey('forecast')) {
        return StationStockDetail.fromJson(raw);
      }

      // Some backends return station detail directly without stock wrapper.
      return StationStockDetail.fromJson(<String, dynamic>{
        'station': raw,
        'forecast': raw['forecast'] ??
            <String, dynamic>{
              'avg_rentals_per_day': 0,
              'projected_demand_30d': 0,
              'recommended_reorder': 0,
            },
        'batteries': _extractList(raw['batteries']),
        'utilization_trend': _extractList(raw['utilization_trend']),
      });
    }

    throw Exception('Invalid station detail response');
  }

  Future<List<StockAlert>> getAlerts() async {
    try {
      final response = await _getAny(<String>[
        '$_baseUrl/alerts',
        '$_altBaseUrl/alerts',
        '/api/v1/admin/inventory/alerts',
      ]);
      final rawItems = _extractList(response.data, keys: <String>[
        'alerts',
        'items',
        'data',
      ]);
      return rawItems
          .whereType<Map>()
          .map((json) => StockAlert.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      // Fallback: derive alerts from stations when explicit alerts endpoint is unavailable.
      final stations = await getStations(alertOnly: true);
      return stations
          .map(
            (s) => StockAlert(
              stationId: s.stationId,
              stationName: s.stationName,
              currentCount: s.availableCount,
              capacity: s.config?.maxCapacity ?? s.totalAssigned,
              threshold: s.config?.reorderPoint ?? 10,
              utilizationPercentage: s.utilizationPercentage,
            ),
          )
          .toList();
    }
  }

  Future<void> dismissAlert(int stationId, String reason) async {
    try {
      await _postAny(<String>[
        '$_baseUrl/alerts/$stationId/dismiss',
        '$_altBaseUrl/alerts/$stationId/dismiss',
      ], queryParameters: <String, dynamic>{'reason': reason});
      return;
    } catch (_) {
      // Retry with JSON payload for backends that reject query params.
      await _postAny(<String>[
        '$_baseUrl/alerts/$stationId/dismiss',
        '$_altBaseUrl/alerts/$stationId/dismiss',
      ], data: <String, dynamic>{'reason': reason});
    }
  }

  Future<void> updateStationConfig(int stationId, StationStockConfig config) async {
    try {
      await _putAny(<String>[
        '$_baseUrl/stations/$stationId/config',
        '$_altBaseUrl/stations/$stationId/config',
      ], data: config.toJson());
      return;
    } catch (_) {
      await _patchAny(<String>[
        '$_baseUrl/stations/$stationId/config',
        '$_altBaseUrl/stations/$stationId/config',
      ], data: config.toJson());
    }
  }

  Future<ReorderRequest> createReorderRequest(
    int stationId,
    int requestedQuantity, {
    String? reason,
  }) async {
    final response = await _postAny(<String>[
      '$_baseUrl/reorder',
      '$_baseUrl/reorder-requests',
      '$_altBaseUrl/reorder',
      '$_altBaseUrl/reorder-requests',
      '/api/v1/admin/inventory/reorder',
      '/api/v1/admin/inventory/reorder-requests',
    ], data: <String, dynamic>{
      'station_id': stationId,
      'requested_quantity': requestedQuantity,
      'quantity': requestedQuantity,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });

    final data = _extractMap(response.data);
    if (data.isEmpty) {
      throw Exception('Invalid reorder response from server');
    }
    return ReorderRequest.fromJson(data);
  }

  Future<Response<dynamic>> _getAny(
    List<String> paths, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.get(path, queryParameters: queryParameters);
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('GET request failed');
  }

  Future<Response<dynamic>> _postAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.post(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('POST request failed');
  }

  Future<Response<dynamic>> _putAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.put(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('PUT request failed');
  }

  Future<Response<dynamic>> _patchAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _api.patch(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('PATCH request failed');
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic data, {List<String> keys = const []}) {
    if (data is List) return data;

    final map = _extractMap(data);
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }

    final nested = map['data'];
    if (nested is List) return nested;
    return const <dynamic>[];
  }
}
