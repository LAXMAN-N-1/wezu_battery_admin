import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrendDataPoint {
  final String label;
  final double value;

  TrendDataPoint({required this.label, required this.value});
}

class StationRevenue {
  final String name;
  final double revenue;
  final int volume;

  StationRevenue({
    required this.name,
    required this.revenue,
    required this.volume,
  });
}

class BatteryTypeRevenue {
  final String type;
  final double revenue;
  final Color color;

  BatteryTypeRevenue({
    required this.type,
    required this.revenue,
    required this.color,
  });
}

class FunnelStage {
  final String label;
  final int count;
  final Color color;

  FunnelStage({required this.label, required this.count, required this.color});
}

class DashboardMetrics {
  final int totalRentals;
  final String revenue;
  final int activeUsers;
  final String fleetUtilization;
  final List<double> rentalTrend;
  final List<Map<String, dynamic>> batteryHealthDistribution;

  // New trend data fields
  final List<TrendDataPoint> dailyRentals;
  final List<TrendDataPoint> weeklyRentals;
  final List<TrendDataPoint> monthlyRentals;
  final List<TrendDataPoint> dailyRevenue;
  final List<TrendDataPoint> weeklyRevenue;
  final List<TrendDataPoint> monthlyRevenue;
  final List<TrendDataPoint> dailyUsers;
  final List<TrendDataPoint> weeklyUsers;
  final List<TrendDataPoint> monthlyUsers;
  final List<TrendDataPoint> dailyHealth;
  final List<TrendDataPoint> weeklyHealth;
  final List<TrendDataPoint> monthlyHealth;

  // Advanced Analytics Fields
  final List<StationRevenue> stationRevenue;
  final List<BatteryTypeRevenue> batteryTypeRevenue;
  final List<FunnelStage> funnelStages;
  final List<String> widgetLayout;
  final bool isRefreshing;

  final DateTime lastUpdated;

  DashboardMetrics({
    required this.totalRentals,
    required this.revenue,
    required this.activeUsers,
    required this.fleetUtilization,
    required this.rentalTrend,
    required this.batteryHealthDistribution,
    required this.dailyRentals,
    required this.weeklyRentals,
    required this.monthlyRentals,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.dailyUsers,
    required this.weeklyUsers,
    required this.monthlyUsers,
    required this.dailyHealth,
    required this.weeklyHealth,
    required this.monthlyHealth,
    required this.stationRevenue,
    required this.batteryTypeRevenue,
    required this.funnelStages,
    required this.widgetLayout,
    this.isRefreshing = true,
    required this.lastUpdated,
  });

  DashboardMetrics copyWith({
    int? totalRentals,
    String? revenue,
    int? activeUsers,
    String? fleetUtilization,
    List<double>? rentalTrend,
    List<Map<String, dynamic>>? batteryHealthDistribution,
    List<TrendDataPoint>? dailyRentals,
    List<TrendDataPoint>? weeklyRentals,
    List<TrendDataPoint>? monthlyRentals,
    List<TrendDataPoint>? dailyRevenue,
    List<TrendDataPoint>? weeklyRevenue,
    List<TrendDataPoint>? monthlyRevenue,
    List<TrendDataPoint>? dailyUsers,
    List<TrendDataPoint>? weeklyUsers,
    List<TrendDataPoint>? monthlyUsers,
    List<TrendDataPoint>? dailyHealth,
    List<TrendDataPoint>? weeklyHealth,
    List<TrendDataPoint>? monthlyHealth,
    List<StationRevenue>? stationRevenue,
    List<BatteryTypeRevenue>? batteryTypeRevenue,
    List<FunnelStage>? funnelStages,
    List<String>? widgetLayout,
    bool? isRefreshing,
    DateTime? lastUpdated,
  }) {
    return DashboardMetrics(
      totalRentals: totalRentals ?? this.totalRentals,
      revenue: revenue ?? this.revenue,
      activeUsers: activeUsers ?? this.activeUsers,
      fleetUtilization: fleetUtilization ?? this.fleetUtilization,
      rentalTrend: rentalTrend ?? this.rentalTrend,
      batteryHealthDistribution:
          batteryHealthDistribution ?? this.batteryHealthDistribution,
      dailyRentals: dailyRentals ?? this.dailyRentals,
      weeklyRentals: weeklyRentals ?? this.weeklyRentals,
      monthlyRentals: monthlyRentals ?? this.monthlyRentals,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      dailyUsers: dailyUsers ?? this.dailyUsers,
      weeklyUsers: weeklyUsers ?? this.weeklyUsers,
      monthlyUsers: monthlyUsers ?? this.monthlyUsers,
      dailyHealth: dailyHealth ?? this.dailyHealth,
      weeklyHealth: weeklyHealth ?? this.weeklyHealth,
      monthlyHealth: monthlyHealth ?? this.monthlyHealth,
      stationRevenue: stationRevenue ?? this.stationRevenue,
      batteryTypeRevenue: batteryTypeRevenue ?? this.batteryTypeRevenue,
      funnelStages: funnelStages ?? this.funnelStages,
      widgetLayout: widgetLayout ?? this.widgetLayout,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardMetrics>((ref) {
      return DashboardNotifier();
    });

class DashboardNotifier extends StateNotifier<DashboardMetrics> {
  Timer? _timer;

  DashboardNotifier()
    : super(
        DashboardMetrics(
          totalRentals: 1284,
          revenue: '₹4.2L',
          activeUsers: 856,
          fleetUtilization: '78%',
          rentalTrend: [300, 450, 380, 600, 550, 800, 850],
          batteryHealthDistribution: [
            {'category': 'Online', 'count': 24, 'color': 'green'},
            {'category': 'Low Stock', 'count': 5, 'color': 'yellow'},
            {'category': 'Offline', 'count': 3, 'color': 'red'},
            {'category': 'Maintenance', 'count': 2, 'color': 'orange'},
          ],
          dailyRentals: _generateData(30, 'Day', 40, 100),
          weeklyRentals: _generateData(12, 'Wk', 300, 800),
          monthlyRentals: _generateData(12, 'Mo', 1200, 3000),
          dailyRevenue: _generateData(30, 'Day', 5000, 15000),
          weeklyRevenue: _generateData(12, 'Wk', 40000, 100000),
          monthlyRevenue: _generateData(12, 'Mo', 200000, 500000),
          dailyUsers: _generateData(30, 'Day', 100, 300),
          weeklyUsers: _generateData(12, 'Wk', 500, 1500),
          monthlyUsers: _generateData(12, 'Mo', 2000, 6000),
          dailyHealth: _generateData(30, 'Day', 85, 95),
          weeklyHealth: _generateData(12, 'Wk', 80, 92),
          monthlyHealth: _generateData(12, 'Mo', 82, 90),
          stationRevenue: [
            StationRevenue(name: 'Indiranagar', revenue: 180000, volume: 450),
            StationRevenue(name: 'Koramangala', revenue: 155000, volume: 400),
            StationRevenue(name: 'HSR Layout', revenue: 120000, volume: 320),
            StationRevenue(name: 'Whitefield', revenue: 95000, volume: 280),
            StationRevenue(name: 'Jayanagar', revenue: 88000, volume: 250),
            StationRevenue(name: 'MG Road', revenue: 75000, volume: 210),
            StationRevenue(name: 'BTM Layout', revenue: 62000, volume: 180),
            StationRevenue(name: 'Malleshwaram', revenue: 58000, volume: 160),
            StationRevenue(
              name: 'Electronic City',
              revenue: 45000,
              volume: 130,
            ),
            StationRevenue(name: 'Banashankari', revenue: 38000, volume: 110),
          ],
          batteryTypeRevenue: [
            BatteryTypeRevenue(
              type: 'Lithium-Ion 60V',
              revenue: 250000,
              color: Colors.blue,
            ),
            BatteryTypeRevenue(
              type: 'Lithium-Ion 48V',
              revenue: 150000,
              color: Colors.green,
            ),
            BatteryTypeRevenue(
              type: 'LFP 60V',
              revenue: 100000,
              color: Colors.orange,
            ),
            BatteryTypeRevenue(
              type: 'LFP 48V',
              revenue: 50000,
              color: Colors.deepPurple,
            ),
          ],
          funnelStages: [
            FunnelStage(label: 'App Installs', count: 5200, color: Colors.blue),
            FunnelStage(
              label: 'Registrations',
              count: 3800,
              color: Colors.purple,
            ),
            FunnelStage(
              label: 'KYC Verified',
              count: 2400,
              color: Colors.orange,
            ),
            FunnelStage(
              label: 'First Rental',
              count: 1200,
              color: Colors.green,
            ),
          ],
          widgetLayout: [
            'trend',
            'health',
            'stations',
            'funnel',
            'activity',
            'insights',
          ],
          lastUpdated: DateTime.now(),
        ),
      ) {
    _startRefreshTimer();
  }

  static List<TrendDataPoint> _generateData(
    int count,
    String prefix,
    double min,
    double max,
  ) {
    return List.generate(count, (i) {
      final value =
          (min +
                  (max - min) * (i / count) +
                  (max - min) * 0.2 * (0.5 - (i % 3 == 0 ? 0.3 : 0.7)))
              .clamp(min, max);
      return TrendDataPoint(label: '$prefix ${i + 1}', value: value);
    });
  }

  void toggleRefresh() {
    if (state.isRefreshing) {
      _timer?.cancel();
    } else {
      _startRefreshTimer();
    }
    state = state.copyWith(isRefreshing: !state.isRefreshing);
  }

  void updateLayout(List<String> newLayout) {
    state = state.copyWith(widgetLayout: newLayout);
  }

  void _startRefreshTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLatestMetrics();
    });
  }

  Future<void> _fetchLatestMetrics() async {
    state = state.copyWith(
      totalRentals: state.totalRentals + (DateTime.now().second % 5),
      activeUsers: state.activeUsers + (DateTime.now().second % 3),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
