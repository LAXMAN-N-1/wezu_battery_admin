import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'dashboard_models.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  static const _base = '/api/v1/admin/analytics';

  Map<String, dynamic> _asMap(
    dynamic data, {
    String? listKey,
    Map<String, dynamic> defaults = const {},
  }) {
    if (data is Map) {
      return {...defaults, ...Map<String, dynamic>.from(data)};
    }
    if (listKey != null && data is List) {
      return {...defaults, listKey: data};
    }
    return defaults;
  }

  /// GET /api/v1/admin/analytics/overview
  Future<DashboardOverview> getOverview() async {
    try {
      final response = await _apiClient.get('$_base/overview');
      return DashboardOverview.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/trends?period=daily
  Future<TrendData> getTrends({String period = 'daily'}) async {
    try {
      final response = await _apiClient.get(
        '$_base/trends',
        queryParameters: {'period': period},
      );
      return TrendData.fromJson(
        _asMap(response.data, listKey: 'data', defaults: {'period': period}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/conversion-funnel
  Future<ConversionFunnel> getConversionFunnel() async {
    try {
      final response = await _apiClient.get('$_base/conversion-funnel');
      return ConversionFunnel.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/battery-health
  Future<BatteryHealthDistribution> getBatteryHealthDistribution() async {
    try {
      final response = await _apiClient.get('$_base/battery-health');
      return BatteryHealthDistribution.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/user-behavior
  Future<UserBehavior> getUserBehavior() async {
    try {
      final response = await _apiClient.get('$_base/user-behavior');
      return UserBehavior.fromJson(_asMap(response.data));
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/demand-forecast
  Future<DemandForecast> getDemandForecast() async {
    try {
      final response = await _apiClient.get('$_base/demand-forecast');
      return DemandForecast.fromJson(
        _asMap(response.data, listKey: 'forecast'),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/revenue-by-region
  Future<RevenueByRegion> getRevenueByRegion() async {
    try {
      final response = await _apiClient.get('$_base/revenue-by-region');
      return RevenueByRegion.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/user-growth?period=monthly
  Future<UserGrowth> getUserGrowth({String period = 'monthly'}) async {
    try {
      final response = await _apiClient.get(
        '$_base/user-growth',
        queryParameters: {'period': period},
      );
      return UserGrowth.fromJson(
        _asMap(response.data, listKey: 'data', defaults: {'period': period}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/inventory-status
  Future<InventoryStatus> getInventoryStatus() async {
    try {
      final response = await _apiClient.get('$_base/inventory-status');
      return InventoryStatus.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/revenue/station
  Future<StationRevenueData> getRevenueByStation({
    String? period,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_base/revenue/station',
        queryParameters: {
          if (period != null) 'period': period,
          'limit': limit,
        },
      );
      return StationRevenueData.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/revenue/battery-type
  Future<BatteryTypeRevenueData> getRevenueByBatteryType({
    String? period,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_base/revenue/battery-type',
        queryParameters: {
          if (period != null) 'period': period,
        },
      );
      return BatteryTypeRevenueData.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/recent-activity
  Future<RecentActivityData> getRecentActivity({String? type}) async {
    try {
      final response = await _apiClient.get(
        '$_base/recent-activity',
        queryParameters: {if (type != null) 'type': type},
      );
      return RecentActivityData.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/top-stations
  Future<TopStationsData> getTopPerformingStations() async {
    try {
      final response = await _apiClient.get('$_base/top-stations');
      return TopStationsData.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      rethrow;
    }
  }
}
