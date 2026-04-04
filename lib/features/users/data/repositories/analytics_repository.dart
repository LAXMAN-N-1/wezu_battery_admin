import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/fraud_risk.dart';
import '../models/suspension_record.dart';
import '../models/invite_link.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(apiClientProvider));
});

class AnalyticsRepository {
  final ApiClient _api;

  AnalyticsRepository(this._api);

  // ─── Analytics Endpoints ───────────────────────────────────────────

  /// Platform KPIs: active users, total rentals, revenue today
  Future<Map<String, dynamic>> getOverview() async {
    final response = await _api.get('/api/v1/admin/analytics/overview');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {};
  }

  /// Daily/weekly/monthly trend data for rentals and revenue
  Future<dynamic> getTrends({String period = '30d'}) async {
    final response = await _api.get(
      '/api/v1/admin/analytics/trends',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  /// Conversion funnel: installs → registrations → first rental
  Future<dynamic> getConversionFunnel() async {
    final response = await _api.get('/api/v1/admin/analytics/conversion-funnel');
    return response.data;
  }

  /// Aggregated user behavior metrics
  Future<dynamic> getUserBehavior() async {
    final response = await _api.get('/api/v1/admin/analytics/user-behavior');
    return response.data;
  }

  /// Distribution of all batteries by health % range
  Future<dynamic> getBatteryHealthDistribution() async {
    final response = await _api.get('/api/v1/admin/analytics/battery-health-distribution');
    return response.data;
  }

  /// 30-day demand forecast per station
  Future<dynamic> getDemandForecast() async {
    final response = await _api.get('/api/v1/admin/analytics/demand-forecast');
    return response.data;
  }

  /// Recent activities
  Future<dynamic> getRecentActivity() async {
    final response = await _api.get('/api/v1/admin/analytics/recent-activity');
    return response.data;
  }

  /// Top stations dashboard data
  Future<dynamic> getTopStations() async {
    final response = await _api.get('/api/v1/admin/analytics/top-stations');
    return response.data;
  }

  /// Revenue distribution by station
  Future<dynamic> getRevenueByStation({String period = '30d'}) async {
    final response = await _api.get(
      '/api/v1/admin/analytics/revenue/by-station',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  /// Revenue split by battery chemistry/model
  Future<dynamic> getRevenueByBatteryType({String period = '30d'}) async {
    final response = await _api.get(
      '/api/v1/admin/analytics/revenue/by-battery-type',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  /// Revenue breakdown by city/region
  Future<dynamic> getRevenueByRegion() async {
    final response = await _api.get('/api/v1/admin/analytics/revenue/by-region');
    return response.data;
  }

  /// User acquisition and retention trends
  Future<dynamic> getUserGrowth({String period = 'monthly'}) async {
    final response = await _api.get(
      '/api/v1/admin/analytics/user-growth',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  /// Health of fleet and hardware utilization summary
  Future<dynamic> getInventoryStatus() async {
    final response = await _api.get('/api/v1/admin/analytics/inventory-status');
    return response.data;
  }

  /// Export analytics report as CSV
  Future<dynamic> exportReport({String reportType = 'overview'}) async {
    final response = await _api.get(
      '/api/v1/admin/analytics/export',
      queryParameters: {'report_type': reportType},
    );
    return response.data;
  }

  // ─── Legacy methods kept for other views ───────────────────────────

  Future<List<FraudRisk>> getFraudRisks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      FraudRisk(
        userId: 10, userName: 'Kavita Reddy', score: 78, level: 'critical',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        factors: const [
          FraudFactor(name: 'Spending Spike', description: '340% increase in spending over 7 days', contribution: 35, severity: 'high'),
          FraudFactor(name: 'Geographic Jump', description: 'Logged in from 3 cities in one day', contribution: 25, severity: 'high'),
          FraudFactor(name: 'Device Changes', description: '4 new devices in last week', contribution: 18, severity: 'medium'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 30)), score: 15),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 25)), score: 20),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 20)), score: 28),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 15)), score: 45),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 62),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 5)), score: 72),
          FraudScoreHistory(date: DateTime.now(), score: 78),
        ],
      ),
      FraudRisk(
        userId: 5, userName: 'Suresh Kumar', score: 62, level: 'high',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
        factors: const [
          FraudFactor(name: 'Non-Compliance', description: 'Multiple policy violations in 30 days', contribution: 30, severity: 'high'),
          FraudFactor(name: 'Rental Anomaly', description: 'Unusual rental pattern detected', contribution: 20, severity: 'medium'),
          FraudFactor(name: 'Late Returns', description: '5 consecutive late battery returns', contribution: 12, severity: 'medium'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 30)), score: 30),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 20)), score: 42),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 55),
          FraudScoreHistory(date: DateTime.now(), score: 62),
        ],
      ),
      FraudRisk(
        userId: 9, userName: 'Vikram Malhotra', score: 45, level: 'medium',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
        factors: const [
          FraudFactor(name: 'Spending Pattern', description: 'Irregular spending pattern detected', contribution: 25, severity: 'medium'),
          FraudFactor(name: 'Multiple Accounts', description: 'Possible duplicate account detected', contribution: 20, severity: 'medium'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 20)), score: 22),
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 35),
          FraudScoreHistory(date: DateTime.now(), score: 45),
        ],
      ),
      FraudRisk(
        userId: 4, userName: 'Priya Singh', score: 22, level: 'low',
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        factors: const [
          FraudFactor(name: 'New User', description: 'Account less than 30 days old', contribution: 12, severity: 'low'),
          FraudFactor(name: 'KYC Pending', description: 'KYC not yet submitted', contribution: 10, severity: 'low'),
        ],
        history: [
          FraudScoreHistory(date: DateTime.now().subtract(const Duration(days: 10)), score: 18),
          FraudScoreHistory(date: DateTime.now(), score: 22),
        ],
      ),
    ];
  }

  Future<List<SuspensionRecord>> getSuspensionHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      SuspensionRecord(
        id: 1, userId: 5, userName: 'Suresh Kumar', reason: 'non_compliance',
        notes: 'Repeated policy violations regarding battery handling',
        suspendedBy: 'Murari Varma', suspendedAt: DateTime(2025, 2, 28),
        reactivateAt: DateTime(2025, 3, 14), isActive: true,
      ),
      SuspensionRecord(
        id: 2, userId: 10, userName: 'Kavita Reddy', reason: 'fraud',
        notes: 'Suspicious financial activity detected — under investigation',
        suspendedBy: 'Murari Varma', suspendedAt: DateTime(2025, 2, 25),
        isActive: true,
      ),
      SuspensionRecord(
        id: 3, userId: 4, userName: 'Priya Singh', reason: 'user_request',
        notes: 'User requested temporary account deactivation',
        suspendedBy: 'Deepak Verma', suspendedAt: DateTime(2025, 2, 10),
        reactivateAt: DateTime(2025, 2, 20),
        reactivatedAt: DateTime(2025, 2, 20), reactivatedBy: 'Deepak Verma',
        isActive: false,
      ),
    ];
  }

  Future<List<InviteLink>> getInviteLinks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      InviteLink(
        id: 1, token: 'inv-a1b2c3d4', email: 'newdriver@gmail.com', role: 'driver',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        createdBy: 'Murari Varma',
      ),
      InviteLink(
        id: 2, token: 'inv-e5f6g7h8', email: 'partner@energyco.in', role: 'dealer',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
        createdBy: 'Murari Varma',
      ),
      InviteLink(
        id: 3, token: 'inv-i9j0k1l2', email: 'oldinvite@test.com', role: 'customer',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 3)),
        createdBy: 'Deepak Verma',
      ),
      InviteLink(
        id: 4, token: 'inv-m3n4o5p6', email: 'usedinvite@test.com', role: 'driver',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'Murari Varma',
        usedAt: DateTime.now().subtract(const Duration(days: 6)),
        isUsed: true,
      ),
    ];
  }
}
