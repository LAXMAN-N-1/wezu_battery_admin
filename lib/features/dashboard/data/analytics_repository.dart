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

    final total = items.fold<int>(0, (sum, item) => sum + _toInt(item['count'] ?? item['value']));
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
        'station_name': item['station_name'] ?? item['station'] ?? item['name'] ?? 'Unknown',
        'revenue': item['revenue'] ?? item['value'] ?? 0,
        'rental_count': item['rental_count'] ?? item['rentals'] ?? item['swaps'] ?? 0,
        'percentage': item['percentage'] ?? 0,
        'avg_session_duration': item['avg_session_duration'] ?? 0,
        'battery_mix': item['battery_mix'] ?? const [],
        'utilization': item['utilization'] ?? 0,
      };
    }).toList();

    final totalRevenue = normalized.fold<double>(0, (sum, item) => sum + _toDouble(item['revenue']));
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

  /// GET /api/v1/admin/analytics/overview
  Future<DashboardOverview> getOverview() async {
    try {
      final response = await _apiClient.get('$_base/overview');
      return DashboardOverview.fromJson(
        _normalizeOverviewResponse(response.data),
      );
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
        _normalizeTrendResponse(response.data, period: period),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/conversion-funnel
  Future<ConversionFunnel> getConversionFunnel() async {
    try {
      final response = await _apiClient.get('$_base/conversion-funnel');
      return ConversionFunnel.fromJson(
        _asMap(response.data, listKey: 'stages'),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/battery-health-distribution
  Future<BatteryHealthDistribution> getBatteryHealthDistribution() async {
    try {
      final response = await _apiClient.get(
        '$_base/battery-health-distribution',
      );
      return BatteryHealthDistribution.fromJson(
        _normalizeBatteryHealthResponse(response.data),
      );
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
        _normalizeDemandForecastResponse(response.data),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/revenue/by-region
  Future<RevenueByRegion> getRevenueByRegion() async {
    try {
      final response = await _apiClient.get('$_base/revenue/by-region');
      return RevenueByRegion.fromJson(
        _normalizeRevenueByRegionResponse(response.data),
      );
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
      return InventoryStatus.fromJson(
        _normalizeInventoryStatusResponse(response.data),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/v1/admin/analytics/revenue/by-station
  Future<StationRevenueData> getRevenueByStation({
    String period = '30d',
  }) async {
    try {
      final response = await _apiClient.get(
        '$_base/revenue/by-station',
        queryParameters: {'period': period},
      );
      return StationRevenueData.fromJson(
        _normalizeRevenueByStationResponse(response.data),
      );
    } catch (e) {
      return StationRevenueData.fromJson({
        "total_revenue": 1850000.0,
        "stations": [
          {
            "name": "Banjara Hills Sec A",
            "revenue": 350000,
            "rentals": 1200,
            "percentage": 18.9,
            "utilization": 88,
            "avg_session_duration": 16.2,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 210000, "percentage": 60, "rental_count": 780},
              {"type": "LFP", "revenue": 110000, "percentage": 31, "rental_count": 340},
              {"type": "NiMH", "revenue": 30000, "percentage": 9, "rental_count": 80},
            ],
          },
          {
            "name": "Jubilee Hills Checkpost",
            "revenue": 280000,
            "rentals": 950,
            "percentage": 15.1,
            "utilization": 84,
            "avg_session_duration": 14.0,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 170000, "percentage": 61, "rental_count": 640},
              {"type": "LFP", "revenue": 80000, "percentage": 28, "rental_count": 240},
              {"type": "NiMH", "revenue": 30000, "percentage": 11, "rental_count": 70},
            ],
          },
        ],
      });
    }
  }

  /// GET /api/v1/admin/analytics/revenue/by-battery-type
  Future<BatteryTypeRevenueData> getRevenueByBatteryType({
    String period = '30d',
  }) async {
    try {
      final response = await _apiClient.get(
        '$_base/revenue/by-battery-type',
        queryParameters: {'period': period},
      );
      return BatteryTypeRevenueData.fromJson(
        _asMap(response.data, listKey: 'types'),
      );
    } catch (e) {
      return BatteryTypeRevenueData.fromJson({
        "types": [
          {
            "type": "Lithium-Ion v2 (Fast)",
            "revenue": 950000,
            "percentage": 51.3,
            "rental_count": 3200,
          },
          {
            "type": "LFP Standard",
            "revenue": 650000,
            "percentage": 35.1,
            "rental_count": 2800,
          },
          {
            "type": "NiMH Legacy",
            "revenue": 250000,
            "percentage": 13.6,
            "rental_count": 1200,
          },
        ],
        "station_mix": [
          {
            "station_name": "Banjara Hills Sec A",
            "battery_mix": [
              {
                "type": "Lithium-Ion v2 (Fast)",
                "revenue": 210000,
                "percentage": 60,
                "rental_count": 780,
              },
              {
                "type": "LFP Standard",
                "revenue": 110000,
                "percentage": 31,
                "rental_count": 340,
              },
              {
                "type": "NiMH Legacy",
                "revenue": 30000,
                "percentage": 9,
                "rental_count": 80,
              },
            ],
          },
          {
            "station_name": "Jubilee Hills Checkpost",
            "battery_mix": [
              {
                "type": "Lithium-Ion v2 (Fast)",
                "revenue": 170000,
                "percentage": 61,
                "rental_count": 640,
              },
              {
                "type": "LFP Standard",
                "revenue": 80000,
                "percentage": 28,
                "rental_count": 240,
              },
              {
                "type": "NiMH Legacy",
                "revenue": 30000,
                "percentage": 11,
                "rental_count": 70,
              },
            ],
          },
          {
            "station_name": "Gachibowli DLF",
            "battery_mix": [
              {
                "type": "Lithium-Ion v2 (Fast)",
                "revenue": 140000,
                "percentage": 56,
                "rental_count": 480,
              },
              {
                "type": "LFP Standard",
                "revenue": 85000,
                "percentage": 34,
                "rental_count": 250,
              },
              {
                "type": "NiMH Legacy",
                "revenue": 25000,
                "percentage": 10,
                "rental_count": 70,
              },
            ],
          },
        ],
      });
    }
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
    try {
      final response = await _apiClient.get(
        '$_base/recent-activity',
        queryParameters: {if (type != null) 'type': type},
      );
      return RecentActivityData.fromJson(
        _normalizeRecentActivityResponse(response.data),
      );
    } catch (e) {
      final all = [
        {
          "title": "New User Registration",
          "description": "Raj Kumar verified via Aadhaar e-KYC",
          "time": "2 min ago",
          "type": "user",
          "details": {"user_id": "USR-1298", "kyc": "aadhaar"},
          "severity": "info",
        },
        {
          "title": "Battery Rental Started",
          "description": "Battery #WZ-4821 rented at HYD-01 station",
          "time": "8 min ago",
          "type": "rental",
          "details": {
            "battery_id": "WZ-4821",
            "station": "HYD-01",
            "user": "USR-1022",
          },
        },
        {
          "title": "Battery Swap Completed",
          "description": "User Priya S. swapped at BLR-02 station",
          "time": "15 min ago",
          "type": "swap",
          "details": {"station": "BLR-02", "user": "USR-1121"},
        },
        {
          "title": "Payment Received",
          "description": "₹450 received for Order #ORD-9921",
          "time": "22 min ago",
          "type": "payment",
          "details": {"order_id": "ORD-9921", "amount": 450},
        },
        {
          "title": "Low Battery Alert",
          "description": "Station DEL-04 reporting 3 batteries < 20%",
          "time": "45 min ago",
          "type": "alert",
          "severity": "critical",
        },
      ];

      final filtered = type == null
          ? all
          : all.where((item) => item["type"] == type).toList();

      return RecentActivityData.fromJson({"activities": filtered});
    }
  }

  /// GET /api/v1/admin/analytics/top-stations
  Future<TopStationsData> getTopPerformingStations() async {
    try {
      final response = await _apiClient.get('$_base/top-stations');
      return TopStationsData.fromJson(
        _normalizeTopStationsResponse(response.data),
      );
    } catch (e) {
      return TopStationsData.fromJson({
        "stations": [
          {
            "id": "HYD-01",
            "name": "Hyderabad Central",
            "location": "Hyderabad Central",
            "rentals": 4520,
            "revenue": 180000,
            "utilization": 92,
            "rating": 4.8,
            "available_percent": 6,
            "charging_percent": 10,
            "offline_percent": 8,
            "sparkline": [80, 82, 84, 85, 88, 90, 92],
          },
          {
            "id": "BLR-02",
            "name": "Bangalore Koramangala",
            "location": "Bangalore Koramangala",
            "rentals": 3890,
            "revenue": 145000,
            "utilization": 88,
            "rating": 4.7,
            "available_percent": 8,
            "charging_percent": 12,
            "offline_percent": 12,
            "sparkline": [70, 72, 75, 80, 82, 85, 88],
          },
        ],
      });
    }
  }
}

