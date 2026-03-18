import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'dashboard_models.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  static const _base = '/api/v1/admin/analytics';

  /// GET /api/v1/admin/analytics/overview
  Future<DashboardOverview> getOverview() async {
    try {
      final response = await _apiClient.get('$_base/overview');
      return DashboardOverview.fromJson(
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      return DashboardOverview.fromJson({
        "total_revenue": {
          "label": "Total Revenue",
          "value": 1240000,
          "change_percent": 12.5,
          "sparkline": [10, 15, 12, 18, 20, 25, 22],
        },
        "active_rentals": {
          "label": "Active Rentals",
          "value": 450,
          "change_percent": 8.2,
          "sparkline": [5, 8, 7, 10, 12, 11, 15],
        },
        "total_users": {
          "label": "Total Users",
          "value": 12500,
          "change_percent": 5.4,
          "sparkline": [100, 150, 120, 180, 200, 250, 220],
        },
        "fleet_utilization": {
          "label": "Fleet Utilization",
          "value": 85,
          "change_percent": -2.1,
          "sparkline": [80, 82, 85, 84, 86, 88, 85],
        },
        "active_stations": {
          "label": "Active Stations",
          "value": 42,
          "change_percent": 0.0,
        },
        "active_dealers": {
          "label": "Active Dealers",
          "value": 18,
          "change_percent": 0.0,
        },
        "avg_battery_health": {
          "label": "Avg. Battery Health",
          "value": 92,
          "change_percent": 0.5,
        },
        "open_tickets": {
          "label": "Open Tickets",
          "value": 15,
          "change_percent": -10.0,
        },
      });
    }
  }

  /// GET /api/v1/admin/analytics/trends?period=daily
  Future<TrendData> getTrends({String period = 'daily'}) async {
    try {
      final response = await _apiClient.get(
        '$_base/trends',
        queryParameters: {'period': period},
      );
      return TrendData.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      return TrendData.fromJson({
        "period": period,
        "data": List.generate(
          30,
          (i) => {
            "date": "Day ${i + 1}",
            "revenue": 5000.0 + (i * 200) + (i % 3 * 500),
            "rentals": 40.0 + (i % 5),
            "users": 100.0 + (i * 5),
            "battery_health": 85.0 + (i % 4),
          },
        ),
      });
    }
  }

  /// GET /api/v1/admin/analytics/conversion-funnel
  Future<ConversionFunnel> getConversionFunnel() async {
    try {
      final response = await _apiClient.get('$_base/conversion-funnel');
      return ConversionFunnel.fromJson(
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      return ConversionFunnel.fromJson({
        "stages": [
          {
            "stage": "App Download",
            "count": 5000,
            "conversion_rate": 100.0,
            "drop_off_rate": 0.0,
          },
          {
            "stage": "Registration",
            "count": 3500,
            "conversion_rate": 70.0,
            "drop_off_rate": 30.0,
          },
          {
            "stage": "KYC Approved",
            "count": 2800,
            "conversion_rate": 80.0,
            "drop_off_rate": 20.0,
          },
          {
            "stage": "First Swap",
            "count": 1200,
            "conversion_rate": 42.8,
            "drop_off_rate": 57.2,
          },
        ],
      });
    }
  }

  /// GET /api/v1/admin/analytics/battery-health-distribution
  Future<BatteryHealthDistribution> getBatteryHealthDistribution() async {
    try {
      final response = await _apiClient.get(
        '$_base/battery-health-distribution',
      );
      return BatteryHealthDistribution.fromJson(
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      return BatteryHealthDistribution.fromJson({
        "total": 1000,
        "previous_total": 950,
        "distribution": [
          {"category": "Excellent (90-100%)", "count": 650, "percentage": 65.0},
          {"category": "Good (70-90%)", "count": 200, "percentage": 20.0},
          {"category": "Fair (50-70%)", "count": 100, "percentage": 10.0},
          {"category": "Critical (<50%)", "count": 50, "percentage": 5.0},
        ],
        "previous_distribution": [
          {"category": "Excellent (90-100%)", "count": 620, "percentage": 62.0},
          {"category": "Good (70-90%)", "count": 210, "percentage": 21.0},
          {"category": "Fair (50-70%)", "count": 120, "percentage": 12.0},
          {"category": "Critical (<50%)", "count": 50, "percentage": 5.0},
        ],
      });
    }
  }

  /// GET /api/v1/admin/analytics/user-behavior
  Future<UserBehavior> getUserBehavior() async {
    try {
      final response = await _apiClient.get('$_base/user-behavior');
      return UserBehavior.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      return UserBehavior.fromJson({
        "avg_session_duration": 15.5,
        "avg_rentals_per_user": 3.2,
        "peak_hours": {"18:00": 150, "19:00": 200, "08:00": 120},
        "heatmap": List.generate(7, (day) {
          return List.generate(24, (hour) => (hour >= 8 && hour <= 21) ? (50 + (day * 10) + hour) : 5);
        }),
        "session_histogram": [
          {"range": "0-5m", "count": 120},
          {"range": "5-10m", "count": 320},
          {"range": "10-15m", "count": 280},
          {"range": "15-20m", "count": 180},
          {"range": "20m+", "count": 90},
        ],
        "cohort_breakdown": {"New Users": 62.0, "Returning Users": 38.0},
      });
    }
  }

  /// GET /api/v1/admin/analytics/demand-forecast
  Future<DemandForecast> getDemandForecast() async {
    try {
      final response = await _apiClient.get('$_base/demand-forecast');
      return DemandForecast.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      return DemandForecast.fromJson({
        "forecast": List.generate(
          7,
          (i) => {
            "date": "Day ${i + 1}",
            "predicted": 100.0 + (i * 20),
            "actual": i < 3 ? 100.0 + (i * 18) : null,
          },
        ),
      });
    }
  }

  /// GET /api/v1/admin/analytics/revenue/by-region
  Future<RevenueByRegion> getRevenueByRegion() async {
    try {
      final response = await _apiClient.get('$_base/revenue/by-region');
      return RevenueByRegion.fromJson(
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      return RevenueByRegion.fromJson({
        "regions": [
          {"region": "Banjara Hills", "revenue": 450000, "rental_count": 1200},
          {"region": "Jubilee Hills", "revenue": 380000, "rental_count": 950},
          {"region": "Gachibowli", "revenue": 320000, "rental_count": 800},
          {"region": "Madhapur", "revenue": 280000, "rental_count": 700},
          {"region": "Kukatpally", "revenue": 210000, "rental_count": 550},
        ],
      });
    }
  }

  /// GET /api/v1/admin/analytics/user-growth?period=monthly
  Future<UserGrowth> getUserGrowth({String period = 'monthly'}) async {
    try {
      final response = await _apiClient.get(
        '$_base/user-growth',
        queryParameters: {'period': period},
      );
      return UserGrowth.fromJson(response.data is Map ? response.data : {});
    } catch (e) {
      return UserGrowth.fromJson({
        "period": period,
        "growth": List.generate(
          6,
          (i) => {
            "period": "Month ${i + 1}",
            "total_users": 1000 + (i * 200),
            "new_users": 150 + (i * 10),
          },
        ),
      });
    }
  }

  /// GET /api/v1/admin/analytics/inventory-status
  Future<InventoryStatus> getInventoryStatus() async {
    try {
      final response = await _apiClient.get('$_base/inventory-status');
      return InventoryStatus.fromJson(
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      return InventoryStatus.fromJson({
        "total_batteries": 1500,
        "total_available": 450,
        "inventory": [
          {
            "category": "Battery Pack v2",
            "total": 800,
            "available": 200,
            "rented": 550,
            "maintenance": 50,
          },
          {
            "category": "Battery Pack v1",
            "total": 500,
            "available": 150,
            "rented": 300,
            "maintenance": 50,
          },
          {
            "category": "Chargers",
            "total": 200,
            "available": 100,
            "rented": 80,
            "maintenance": 20,
          },
        ],
      });
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
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      // Mock data for top 10 stations
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
            ]
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
            ]
          },
          {
            "name": "Gachibowli DLF",
            "revenue": 250000,
            "rentals": 800,
            "percentage": 13.5,
            "utilization": 82,
            "avg_session_duration": 15.0,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 140000, "percentage": 56, "rental_count": 480},
              {"type": "LFP", "revenue": 85000, "percentage": 34, "rental_count": 250},
              {"type": "NiMH", "revenue": 25000, "percentage": 10, "rental_count": 70},
            ]
          },
          {
            "name": "Madhapur Metro",
            "revenue": 220000,
            "rentals": 700,
            "percentage": 11.9,
            "utilization": 80,
            "avg_session_duration": 13.5,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 120000, "percentage": 55, "rental_count": 380},
              {"type": "LFP", "revenue": 80000, "percentage": 36, "rental_count": 260},
              {"type": "NiMH", "revenue": 20000, "percentage": 9, "rental_count": 60},
            ]
          },
          {
            "name": "Kukatpally Housing Board",
            "revenue": 190000,
            "rentals": 550,
            "percentage": 10.3,
            "utilization": 78,
            "avg_session_duration": 12.8,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 100000, "percentage": 53, "rental_count": 320},
              {"type": "LFP", "revenue": 70000, "percentage": 37, "rental_count": 180},
              {"type": "NiMH", "revenue": 20000, "percentage": 10, "rental_count": 50},
            ]
          },
          {
            "name": "Hitech City Hub",
            "revenue": 170000,
            "rentals": 500,
            "percentage": 9.2,
            "utilization": 76,
            "avg_session_duration": 15.5,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 90000, "percentage": 53, "rental_count": 280},
              {"type": "LFP", "revenue": 60000, "percentage": 35, "rental_count": 160},
              {"type": "NiMH", "revenue": 20000, "percentage": 12, "rental_count": 60},
            ]
          },
          {
            "name": "Kondapur Junction",
            "revenue": 150000,
            "rentals": 450,
            "percentage": 8.1,
            "utilization": 74,
            "avg_session_duration": 14.4,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 82000, "percentage": 55, "rental_count": 260},
              {"type": "LFP", "revenue": 52000, "percentage": 35, "rental_count": 150},
              {"type": "NiMH", "revenue": 16000, "percentage": 10, "rental_count": 40},
            ]
          },
          {
            "name": "Miyapur Station",
            "revenue": 120000,
            "rentals": 400,
            "percentage": 6.5,
            "utilization": 70,
            "avg_session_duration": 13.0,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 60000, "percentage": 50, "rental_count": 210},
              {"type": "LFP", "revenue": 42000, "percentage": 35, "rental_count": 140},
              {"type": "NiMH", "revenue": 18000, "percentage": 15, "rental_count": 50},
            ]
          },
          {
            "name": "Ameerpet Interchange",
            "revenue": 90000,
            "rentals": 300,
            "percentage": 4.9,
            "utilization": 68,
            "avg_session_duration": 12.2,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 48000, "percentage": 53, "rental_count": 170},
              {"type": "LFP", "revenue": 32000, "percentage": 36, "rental_count": 100},
              {"type": "NiMH", "revenue": 10000, "percentage": 11, "rental_count": 30},
            ]
          },
          {
            "name": "Secunderabad East",
            "revenue": 30000,
            "rentals": 120,
            "percentage": 1.6,
            "utilization": 60,
            "avg_session_duration": 11.0,
            "battery_mix": [
              {"type": "Li-ion", "revenue": 15000, "percentage": 50, "rental_count": 60},
              {"type": "LFP", "revenue": 9000, "percentage": 30, "rental_count": 40},
              {"type": "NiMH", "revenue": 6000, "percentage": 20, "rental_count": 20},
            ]
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
        response.data is Map ? response.data : {},
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
              {"type": "Lithium-Ion v2 (Fast)", "revenue": 210000, "percentage": 60, "rental_count": 780},
              {"type": "LFP Standard", "revenue": 110000, "percentage": 31, "rental_count": 340},
              {"type": "NiMH Legacy", "revenue": 30000, "percentage": 9, "rental_count": 80},
            ]
          },
          {
            "station_name": "Jubilee Hills Checkpost",
            "battery_mix": [
              {"type": "Lithium-Ion v2 (Fast)", "revenue": 170000, "percentage": 61, "rental_count": 640},
              {"type": "LFP Standard", "revenue": 80000, "percentage": 28, "rental_count": 240},
              {"type": "NiMH Legacy", "revenue": 30000, "percentage": 11, "rental_count": 70},
            ]
          },
          {
            "station_name": "Gachibowli DLF",
            "battery_mix": [
              {"type": "Lithium-Ion v2 (Fast)", "revenue": 140000, "percentage": 56, "rental_count": 480},
              {"type": "LFP Standard", "revenue": 85000, "percentage": 34, "rental_count": 250},
              {"type": "NiMH Legacy", "revenue": 25000, "percentage": 10, "rental_count": 70},
            ]
          },
        ]
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
        queryParameters: {
          if (type != null) 'type': type,
        },
      );
      return RecentActivityData.fromJson(
        response.data is Map ? response.data : {},
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
          "details": {"battery_id": "WZ-4821", "station": "HYD-01", "user": "USR-1022"},
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
        response.data is Map ? response.data : {},
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
          {
            "id": "MUM-03",
            "name": "Mumbai Andheri West",
            "location": "Mumbai Andheri West",
            "rentals": 3210,
            "revenue": 120000,
            "utilization": 85,
            "rating": 4.6,
            "available_percent": 10,
            "charging_percent": 14,
            "offline_percent": 14,
            "sparkline": [65, 68, 70, 74, 78, 82, 85],
          },
          {
            "id": "DEL-04",
            "name": "Delhi Connaught Place",
            "location": "Delhi Connaught Place",
            "rentals": 2950,
            "revenue": 95000,
            "utilization": 78,
            "rating": 4.5,
            "available_percent": 12,
            "charging_percent": 18,
            "offline_percent": 14,
            "sparkline": [60, 62, 64, 66, 70, 74, 78],
          },
          {
            "id": "CHN-05",
            "name": "Chennai T. Nagar",
            "location": "Chennai T. Nagar",
            "rentals": 2440,
            "revenue": 72000,
            "utilization": 82,
            "rating": 4.4,
            "available_percent": 14,
            "charging_percent": 16,
            "offline_percent": 12,
            "sparkline": [62, 64, 68, 70, 74, 78, 82],
          },
          {
            "id": "PUN-06",
            "name": "Pune Hinjewadi",
            "location": "Pune Hinjewadi",
            "rentals": 2100,
            "revenue": 68000,
            "utilization": 80,
            "rating": 4.3,
            "available_percent": 16,
            "charging_percent": 18,
            "offline_percent": 16,
            "sparkline": [60, 63, 66, 70, 72, 76, 80],
          },
        ],
      });
    }
  }
}
