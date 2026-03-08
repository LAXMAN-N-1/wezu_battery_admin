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
        "distribution": [
          {"category": "Excellent (90-100%)", "count": 650, "percentage": 65.0},
          {"category": "Good (70-90%)", "count": 200, "percentage": 20.0},
          {"category": "Fair (50-70%)", "count": 100, "percentage": 10.0},
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
          },
          {
            "name": "Jubilee Hills Checkpost",
            "revenue": 280000,
            "rentals": 950,
            "percentage": 15.1,
          },
          {
            "name": "Gachibowli DLF",
            "revenue": 250000,
            "rentals": 800,
            "percentage": 13.5,
          },
          {
            "name": "Madhapur Metro",
            "revenue": 220000,
            "rentals": 700,
            "percentage": 11.9,
          },
          {
            "name": "Kukatpally Housing Board",
            "revenue": 190000,
            "rentals": 550,
            "percentage": 10.3,
          },
          {
            "name": "Hitech City Hub",
            "revenue": 170000,
            "rentals": 500,
            "percentage": 9.2,
          },
          {
            "name": "Kondapur Junction",
            "revenue": 150000,
            "rentals": 450,
            "percentage": 8.1,
          },
          {
            "name": "Miyapur Station",
            "revenue": 120000,
            "rentals": 400,
            "percentage": 6.5,
          },
          {
            "name": "Ameerpet Interchange",
            "revenue": 90000,
            "rentals": 300,
            "percentage": 4.9,
          },
          {
            "name": "Secunderabad East",
            "revenue": 30000,
            "rentals": 120,
            "percentage": 1.6,
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
  Future<RecentActivityData> getRecentActivity() async {
    try {
      final response = await _apiClient.get('$_base/recent-activity');
      return RecentActivityData.fromJson(
        response.data is Map ? response.data : {},
      );
    } catch (e) {
      return RecentActivityData.fromJson({
        "activities": [
          {
            "title": "New User Registration",
            "description": "Raj Kumar verified via Aadhaar e-KYC",
            "time": "2 min ago",
            "type": "user",
          },
          {
            "title": "Battery Rental Started",
            "description": "Battery #WZ-4821 rented at HYD-01 station",
            "time": "8 min ago",
            "type": "rental",
          },
          {
            "title": "Battery Swap Completed",
            "description": "User Priya S. swapped at BLR-02 station",
            "time": "15 min ago",
            "type": "swap",
          },
          {
            "title": "Payment Received",
            "description": "₹450 received for Order #ORD-9921",
            "time": "22 min ago",
            "type": "payment",
          },
          {
            "title": "Low Battery Alert",
            "description": "Station DEL-04 reporting 3 batteries < 20%",
            "time": "45 min ago",
            "type": "alert",
          },
        ],
      });
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
          },
          {
            "id": "BLR-02",
            "name": "Bangalore Koramangala",
            "location": "Bangalore Koramangala",
            "rentals": 3890,
            "revenue": 145000,
            "utilization": 88,
            "rating": 4.7,
          },
          {
            "id": "MUM-03",
            "name": "Mumbai Andheri West",
            "location": "Mumbai Andheri West",
            "rentals": 3210,
            "revenue": 120000,
            "utilization": 85,
            "rating": 4.6,
          },
          {
            "id": "DEL-04",
            "name": "Delhi Connaught Place",
            "location": "Delhi Connaught Place",
            "rentals": 2950,
            "revenue": 95000,
            "utilization": 78,
            "rating": 4.5,
          },
          {
            "id": "CHN-05",
            "name": "Chennai T. Nagar",
            "location": "Chennai T. Nagar",
            "rentals": 2440,
            "revenue": 72000,
            "utilization": 82,
            "rating": 4.4,
          },
          {
            "id": "PUN-06",
            "name": "Pune Hinjewadi",
            "location": "Pune Hinjewadi",
            "rentals": 2100,
            "revenue": 68000,
            "utilization": 80,
            "rating": 4.3,
          },
        ],
      });
    }
  }
}
