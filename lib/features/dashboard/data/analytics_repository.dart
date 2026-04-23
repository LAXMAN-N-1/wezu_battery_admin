import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_cache.dart';
import 'dashboard_models.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;
  final ApiCache _cache = ApiCache();

  AnalyticsRepository(this._apiClient);

  static const _base = '/api/v1/admin/analytics';
  static const _adminStatsPath = '/api/v1/admin/stats';

  bool _isPermissionDenied(Object error) {
    return error is DioException && error.response?.statusCode == 403;
  }

  DashboardOverview _emptyOverview() {
    return DashboardOverview.fromJson(const {});
  }

  TrendData _emptyTrends(String period) {
    return TrendData.fromJson({'period': period, 'data': const []});
  }

  ConversionFunnel _emptyConversionFunnel() {
    return ConversionFunnel.fromJson(const {'stages': []});
  }

  BatteryHealthDistribution _emptyBatteryHealthDistribution() {
    return BatteryHealthDistribution.fromJson(const {'distribution': []});
  }

  UserBehavior _emptyUserBehavior() {
    return UserBehavior.fromJson(const {});
  }

  DemandForecast _emptyDemandForecast() {
    return DemandForecast.fromJson(const {'forecast': []});
  }

  RevenueByRegion _emptyRevenueByRegion() {
    return RevenueByRegion.fromJson(const {'regions': []});
  }

  UserGrowth _emptyUserGrowth(String period) {
    return UserGrowth.fromJson({'period': period, 'data': const []});
  }

  InventoryStatus _emptyInventoryStatus() {
    return InventoryStatus.fromJson(const {'inventory': []});
  }

  StationRevenueData _emptyRevenueByStation() {
    return StationRevenueData.fromJson(const {'stations': []});
  }

  BatteryTypeRevenueData _emptyRevenueByBatteryType() {
    return BatteryTypeRevenueData.fromJson(const {'types': []});
  }

  RecentActivityData _emptyRecentActivity() {
    return RecentActivityData.fromJson(const {'activities': []});
  }

  TopStationsData _emptyTopStations() {
    return TopStationsData.fromJson(const {'stations': []});
  }

  DashboardBootstrapData _emptyBootstrap(
    String period, {
    Map<String, dynamic>? overview,
  }) {
    return DashboardBootstrapData.fromJson({
      'period': period,
      'overview': overview ?? const {},
      'trends': {'period': period, 'data': const []},
      'conversion_funnel': const {'stages': []},
      'battery_health_distribution': const {'distribution': []},
      'inventory_status': const {'inventory': []},
      'demand_forecast': const {'forecast': []},
      'revenue_by_station': const {'stations': []},
      'recent_activity': const {'activities': []},
      'top_stations': const {'stations': []},
    });
  }

  Map<String, dynamic> _adminStatsOverviewJson(Map<String, dynamic> stats) {
    return {
      'total_revenue': 0,
      'active_rentals': stats['active_rentals'] ?? 0,
      'total_users': stats['total_users'] ?? 0,
      'fleet_utilization': 0,
      'active_stations': stats['total_stations'] ?? 0,
      'active_dealers': 0,
      'avg_battery_health': 0,
      'open_tickets': stats['pending_kyc'] ?? 0,
      'revenue_per_rental': 0,
      'avg_session_duration': 0,
    };
  }

  Future<DashboardOverview> _getAdminStatsOverview() async {
    final response = await _apiClient.get(_adminStatsPath);
    final stats = _asMap(response.data);
    return DashboardOverview.fromJson(_adminStatsOverviewJson(stats));
  }

  Future<DashboardBootstrapData> _getPermissionFallbackBootstrap(
    String period,
  ) async {
    try {
      final response = await _apiClient.get(_adminStatsPath);
      return _emptyBootstrap(
        period,
        overview: _adminStatsOverviewJson(_asMap(response.data)),
      );
    } catch (_) {
      return _emptyBootstrap(period);
    }
  }

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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _normalizeOverviewResponse(dynamic data) {
    final map = _asMap(data);
    if (map.containsKey('total_revenue') || map.containsKey('metrics')) {
      return map;
    }

    final revenue = _asMap(map['revenue']);
    final activeUsers = _asMap(map['active_users']);
    final swaps = _asMap(map['battery_swaps']);
    final utilization = _asMap(map['fleet_utilization']);

    return {
      'total_revenue': {
        'label': 'Total Revenue',
        'value': revenue['total'] ?? 0,
        'change_percent': revenue['growth'] ?? 0,
      },
      'active_rentals': {
        'label': 'Active Rentals',
        'value': swaps['total'] ?? 0,
        'change_percent': swaps['growth'] ?? 0,
      },
      'total_users': {
        'label': 'Total Users',
        'value': activeUsers['total'] ?? 0,
        'change_percent': activeUsers['growth'] ?? 0,
      },
      'fleet_utilization': {
        'label': 'Fleet Utilization',
        'value': utilization['percentage'] ?? 0,
        'change_percent': utilization['growth'] ?? 0,
      },
      'active_stations': {'label': 'Active Stations', 'value': 0},
      'active_dealers': {'label': 'Active Dealers', 'value': 0},
      'avg_battery_health': {'label': 'Avg. Battery Health', 'value': 0},
      'open_tickets': {'label': 'Open Tickets', 'value': 0},
      'revenue_per_rental': {'label': 'Rev. per Rental', 'value': 0},
      'avg_session_duration': {'label': 'Avg. Session', 'value': 0},
    };
  }

  Map<String, dynamic> _normalizeTrendResponse(
    dynamic data, {
    required String period,
  }) {
    final map = _asMap(data, defaults: {'period': period});
    if (map['data'] is List) {
      return map;
    }

    final dates = map['dates'];
    final revenue = map['revenue'];
    final swaps = map['swaps'];
    if (dates is! List || revenue is! List) {
      return map;
    }

    final points = <Map<String, dynamic>>[];
    final maxLen = dates.length;
    for (var i = 0; i < maxLen; i++) {
      points.add({
        'date': dates[i].toString(),
        'revenue': i < revenue.length ? _toDouble(revenue[i]) : 0,
        'rentals': swaps is List && i < swaps.length ? _toDouble(swaps[i]) : 0,
        'users': 0,
        'battery_health': 0,
      });
    }

    return {'period': period, 'data': points};
  }

  Map<String, dynamic> _normalizeBatteryHealthResponse(dynamic data) {
    if (data is Map) {
      return _asMap(data);
    }

    final items = _asListOfMaps(data);
    if (items.isEmpty) {
      return const {};
    }

    final total = items.fold<int>(
      0,
      (sum, item) => sum + _toInt(item['count'] ?? item['value']),
    );
    final distribution = items.map((item) {
      final count = _toInt(item['count'] ?? item['value']);
      final percentage = total > 0 ? (count * 100) / total : 0.0;
      return {
        'category': item['status'] ?? item['category'] ?? 'Unknown',
        'count': count,
        'percentage': percentage,
      };
    }).toList();

    return {'total': total, 'distribution': distribution};
  }

  Map<String, dynamic> _normalizeRevenueByRegionResponse(dynamic data) {
    if (data is Map) {
      return _asMap(data, listKey: 'regions');
    }

    final items = _asListOfMaps(data).map((item) {
      return {
        'region': item['region'] ?? item['name'] ?? 'Unknown',
        'revenue': item['revenue'] ?? item['value'] ?? 0,
        'rental_count': item['rental_count'] ?? item['rentals'] ?? 0,
      };
    }).toList();

    return {'regions': items};
  }

  Map<String, dynamic> _normalizeInventoryStatusResponse(dynamic data) {
    final map = _asMap(data);
    if (map['inventory'] is List || map['items'] is List) {
      return map;
    }

    final available = _toInt(map['available']);
    final inTransit = _toInt(map['in_transit']);
    final maintenance = _toInt(map['maintenance']);
    final dispatched = _toInt(map['dispatched']);
    final total = available + inTransit + maintenance + dispatched;

    return {
      'total_batteries': total,
      'total_available': available,
      'inventory': [
        {
          'category': 'Available',
          'total': available,
          'available': available,
          'rented': 0,
          'maintenance': 0,
        },
        {
          'category': 'Dispatched',
          'total': dispatched,
          'available': 0,
          'rented': dispatched,
          'maintenance': 0,
        },
        {
          'category': 'In Transit',
          'total': inTransit,
          'available': 0,
          'rented': inTransit,
          'maintenance': 0,
        },
        {
          'category': 'Maintenance',
          'total': maintenance,
          'available': 0,
          'rented': 0,
          'maintenance': maintenance,
        },
      ],
    };
  }

  Map<String, dynamic> _normalizeDemandForecastResponse(dynamic data) {
    final map = _asMap(data);
    final forecast = map['forecast'];
    if (forecast is List && (forecast.isEmpty || forecast.first is Map)) {
      return map;
    }

    final dates = map['dates'];
    if (dates is! List || forecast is! List) {
      return map;
    }

    final points = <Map<String, dynamic>>[];
    for (var i = 0; i < dates.length; i++) {
      points.add({
        'date': dates[i].toString(),
        'predicted': i < forecast.length ? _toDouble(forecast[i]) : 0,
        'actual': null,
      });
    }

    return {'forecast': points};
  }

  Map<String, dynamic> _normalizeRevenueByStationResponse(dynamic data) {
    final map = _asMap(data, listKey: 'stations');
    final stations = _asListOfMaps(map['stations']);
    if (stations.isEmpty) {
      return map;
    }

    final normalized = stations.map((item) {
      return {
        'station_name':
            item['station_name'] ??
            item['station'] ??
            item['name'] ??
            'Unknown',
        'revenue': item['revenue'] ?? item['value'] ?? 0,
        'rental_count':
            item['rental_count'] ?? item['rentals'] ?? item['swaps'] ?? 0,
        'percentage': item['percentage'] ?? 0,
        'avg_session_duration': item['avg_session_duration'] ?? 0,
        'battery_mix': item['battery_mix'] ?? const [],
        'utilization': item['utilization'] ?? 0,
      };
    }).toList();

    final totalRevenue = normalized.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['revenue']),
    );
    return {'total_revenue': totalRevenue, 'stations': normalized};
  }

  String _activityTitleForType(String type) {
    switch (type) {
      case 'swap':
        return 'Battery Swap Completed';
      case 'payment':
        return 'Payment Received';
      case 'rental':
        return 'Battery Rental Started';
      case 'alert':
        return 'Operational Alert';
      case 'user':
      default:
        return 'User Activity';
    }
  }

  Map<String, dynamic> _normalizeRecentActivityResponse(dynamic data) {
    final map = _asMap(data, listKey: 'activities');
    final activities = _asListOfMaps(map['activities']);
    if (activities.isEmpty) {
      return map;
    }

    return {
      'activities': activities.map((item) {
        final type = item['type']?.toString() ?? 'user';
        return {
          'title': item['title'] ?? _activityTitleForType(type),
          'description': item['description'] ?? '',
          'time': item['time'] ?? item['timestamp'] ?? '',
          'type': type,
          'details': item['details'] ?? {'id': item['id']},
          'severity': item['severity'],
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _normalizeTopStationsResponse(dynamic data) {
    final map = _asMap(data, listKey: 'stations');
    final stations = _asListOfMaps(map['stations']);
    if (stations.isEmpty) {
      return map;
    }

    return {
      'stations': stations.map((item) {
        return {
          'id': item['id'] ?? '',
          'name': item['name'] ?? 'Unknown',
          'location': item['location'] ?? item['status'] ?? 'Unknown',
          'rentals': item['rentals'] ?? item['swaps'] ?? 0,
          'revenue': item['revenue'] ?? 0,
          'utilization': item['utilization'] ?? 0,
          'rating': item['rating'] ?? 0,
          'available_percent': item['available_percent'] ?? 0,
          'charging_percent': item['charging_percent'] ?? 0,
          'offline_percent': item['offline_percent'] ?? 0,
          'sparkline': item['sparkline'] ?? const [],
        };
      }).toList(),
    };
  }

  Future<DashboardBootstrapData> getDashboardBootstrap({
    String period = '30d',
  }) async {
    return _cache.getOrFetch<DashboardBootstrapData>(
      'bootstrap_$period',
      ttl: const Duration(seconds: 60),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/dashboard',
            queryParameters: {'period': period},
          );
          final map = _asMap(response.data, defaults: {'period': period});
          final normalizedPeriod = map['period']?.toString() ?? period;

          return DashboardBootstrapData.fromJson({
            'period': normalizedPeriod,
            'generated_at': map['generated_at'],
            'overview': _normalizeOverviewResponse(map['overview']),
            'trends': _normalizeTrendResponse(
              map['trends'],
              period: normalizedPeriod,
            ),
            'conversion_funnel': _asMap(
              map['conversion_funnel'],
              listKey: 'stages',
            ),
            'battery_health_distribution': _normalizeBatteryHealthResponse(
              map['battery_health_distribution'],
            ),
            'inventory_status': _normalizeInventoryStatusResponse(
              map['inventory_status'],
            ),
            'demand_forecast': _normalizeDemandForecastResponse(
              map['demand_forecast'],
            ),
            'revenue_by_station': _normalizeRevenueByStationResponse(
              map['revenue_by_station'],
            ),
            'recent_activity': _normalizeRecentActivityResponse(
              map['recent_activity'],
            ),
            'top_stations': _normalizeTopStationsResponse(map['top_stations']),
          });
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _getPermissionFallbackBootstrap(period);
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/overview
  Future<DashboardOverview> getOverview() async {
    return _cache.getOrFetch<DashboardOverview>(
      'overview',
      ttl: const Duration(seconds: 60),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/overview');
          return DashboardOverview.fromJson(
            _normalizeOverviewResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          try {
            return await _getAdminStatsOverview();
          } catch (_) {
            return _emptyOverview();
          }
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/trends?period=daily
  Future<TrendData> getTrends({String period = 'daily'}) async {
    return _cache.getOrFetch<TrendData>(
      'trends_$period',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/trends',
            queryParameters: {'period': period},
          );
          return TrendData.fromJson(
            _normalizeTrendResponse(response.data, period: period),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyTrends(period);
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/conversion-funnel
  Future<ConversionFunnel> getConversionFunnel() async {
    return _cache.getOrFetch<ConversionFunnel>(
      'conversion_funnel',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/conversion-funnel');
          return ConversionFunnel.fromJson(
            _asMap(response.data, listKey: 'stages'),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyConversionFunnel();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/battery-health-distribution
  Future<BatteryHealthDistribution> getBatteryHealthDistribution() async {
    return _cache.getOrFetch<BatteryHealthDistribution>(
      'battery_health',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/battery-health-distribution',
          );
          return BatteryHealthDistribution.fromJson(
            _normalizeBatteryHealthResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyBatteryHealthDistribution();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/user-behavior
  Future<UserBehavior> getUserBehavior() async {
    return _cache.getOrFetch<UserBehavior>(
      'user_behavior',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/user-behavior');
          return UserBehavior.fromJson(_asMap(response.data));
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyUserBehavior();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/demand-forecast
  Future<DemandForecast> getDemandForecast() async {
    return _cache.getOrFetch<DemandForecast>(
      'demand_forecast',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/demand-forecast');
          return DemandForecast.fromJson(
            _normalizeDemandForecastResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyDemandForecast();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/revenue/by-region
  Future<RevenueByRegion> getRevenueByRegion() async {
    return _cache.getOrFetch<RevenueByRegion>(
      'revenue_by_region',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/revenue/by-region');
          return RevenueByRegion.fromJson(
            _normalizeRevenueByRegionResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyRevenueByRegion();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/user-growth?period=monthly
  Future<UserGrowth> getUserGrowth({String period = 'monthly'}) async {
    return _cache.getOrFetch<UserGrowth>(
      'user_growth_$period',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/user-growth',
            queryParameters: {'period': period},
          );
          return UserGrowth.fromJson(
            _asMap(
              response.data,
              listKey: 'data',
              defaults: {'period': period},
            ),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyUserGrowth(period);
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/inventory-status
  Future<InventoryStatus> getInventoryStatus() async {
    return _cache.getOrFetch<InventoryStatus>(
      'inventory_status',
      ttl: const Duration(minutes: 2),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/inventory-status');
          return InventoryStatus.fromJson(
            _normalizeInventoryStatusResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyInventoryStatus();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/revenue/by-station
  Future<StationRevenueData> getRevenueByStation({
    String period = '30d',
  }) async {
    return _cache.getOrFetch<StationRevenueData>(
      'revenue_by_station_$period',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/revenue/by-station',
            queryParameters: {'period': period},
          );
          return StationRevenueData.fromJson(
            _normalizeRevenueByStationResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyRevenueByStation();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/revenue/by-battery-type
  Future<BatteryTypeRevenueData> getRevenueByBatteryType({
    String period = '30d',
  }) async {
    return _cache.getOrFetch<BatteryTypeRevenueData>(
      'revenue_by_battery_type_$period',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/revenue/by-battery-type',
            queryParameters: {'period': period},
          );
          return BatteryTypeRevenueData.fromJson(
            _asMap(response.data, listKey: 'types'),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyRevenueByBatteryType();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/export?report_type=overview
  /// Returns raw response bytes for CSV download.
  Future<Response> exportReport({String reportType = 'overview'}) async {
    return await _apiClient.dio.get(
      '$_base/export',
      queryParameters: {'report_type': reportType},
      options: Options(responseType: ResponseType.bytes),
    );
  }

  /// GET /api/v1/admin/analytics/recent-activity
  Future<RecentActivityData> getRecentActivity({String? type}) async {
    return _cache.getOrFetch<RecentActivityData>(
      'recent_activity_${type ?? 'all'}',
      ttl: const Duration(seconds: 60),
      fetch: () async {
        try {
          final response = await _apiClient.get(
            '$_base/recent-activity',
            queryParameters: {if (type != null) 'type': type},
          );
          return RecentActivityData.fromJson(
            _normalizeRecentActivityResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyRecentActivity();
        }
      },
    );
  }

  /// GET /api/v1/admin/analytics/top-stations
  Future<TopStationsData> getTopPerformingStations() async {
    return _cache.getOrFetch<TopStationsData>(
      'top_stations',
      ttl: const Duration(minutes: 5),
      fetch: () async {
        try {
          final response = await _apiClient.get('$_base/top-stations');
          return TopStationsData.fromJson(
            _normalizeTopStationsResponse(response.data),
          );
        } on DioException catch (error) {
          if (!_isPermissionDenied(error)) rethrow;
          return _emptyTopStations();
        }
      },
    );
  }
}
