import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/analytics_repository.dart';
import '../../dashboard/providers/dashboard_providers.dart';

// ─── State ───────────────────────────────────────────────────────────

class AnalyticsState {
  final bool isLoading;
  final String? error;

  // Overview KPIs
  final Map<String, dynamic> overview;

  // Trends (daily/weekly/monthly)
  final dynamic trends;
  final String trendsPeriod;

  // Conversion funnel
  final dynamic conversionFunnel;

  // User behavior
  final dynamic userBehavior;

  // Battery health distribution
  final dynamic batteryHealth;

  // Demand forecast
  final dynamic demandForecast;

  // Recent activity
  final dynamic recentActivity;

  // Top stations
  final dynamic topStations;

  // Revenue by region
  final dynamic revenueByRegion;

  // Revenue by station
  final dynamic revenueByStation;

  // Revenue by battery type
  final dynamic revenueByBatteryType;

  // User growth
  final dynamic userGrowth;
  final String userGrowthPeriod;

  // Inventory status
  final dynamic inventoryStatus;

  AnalyticsState({
    this.isLoading = true,
    this.error,
    this.overview = const {},
    this.trends,
    this.trendsPeriod = 'daily',
    this.conversionFunnel,
    this.userBehavior,
    this.batteryHealth,
    this.demandForecast,
    this.recentActivity,
    this.topStations,
    this.revenueByRegion,
    this.revenueByStation,
    this.revenueByBatteryType,
    this.userGrowth,
    this.userGrowthPeriod = 'monthly',
    this.inventoryStatus,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? overview,
    dynamic trends,
    String? trendsPeriod,
    dynamic conversionFunnel,
    dynamic userBehavior,
    dynamic batteryHealth,
    dynamic demandForecast,
    dynamic recentActivity,
    dynamic topStations,
    dynamic revenueByRegion,
    dynamic revenueByStation,
    dynamic revenueByBatteryType,
    dynamic userGrowth,
    String? userGrowthPeriod,
    dynamic inventoryStatus,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      overview: overview ?? this.overview,
      trends: trends ?? this.trends,
      trendsPeriod: trendsPeriod ?? this.trendsPeriod,
      conversionFunnel: conversionFunnel ?? this.conversionFunnel,
      userBehavior: userBehavior ?? this.userBehavior,
      batteryHealth: batteryHealth ?? this.batteryHealth,
      demandForecast: demandForecast ?? this.demandForecast,
      recentActivity: recentActivity ?? this.recentActivity,
      topStations: topStations ?? this.topStations,
      revenueByRegion: revenueByRegion ?? this.revenueByRegion,
      revenueByStation: revenueByStation ?? this.revenueByStation,
      revenueByBatteryType: revenueByBatteryType ?? this.revenueByBatteryType,
      userGrowth: userGrowth ?? this.userGrowth,
      userGrowthPeriod: userGrowthPeriod ?? this.userGrowthPeriod,
      inventoryStatus: inventoryStatus ?? this.inventoryStatus,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier(this._repository) : super(AnalyticsState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait<dynamic>([
        _repository.getOverview(),                                  // 0
        _repository.getTrends(period: state.trendsPeriod),          // 1
        _repository.getConversionFunnel(),                          // 2
        _repository.getUserBehavior(),                              // 3
        _repository.getBatteryHealthDistribution(),                 // 4
        _repository.getDemandForecast(),                            // 5
        _repository.getRecentActivity(),                            // 6
        _repository.getTopPerformingStations(),                     // 7
        _repository.getRevenueByRegion(),                           // 8
        _repository.getUserGrowth(period: state.userGrowthPeriod),  // 9
        _repository.getInventoryStatus(),                           // 10
        _repository.getRevenueByStation(period: '30d'),             // 11
        _repository.getRevenueByBatteryType(period: '30d'),         // 12
      ]);

      state = state.copyWith(
        isLoading: false,
        overview: results[0] is Map<String, dynamic> ? results[0] as Map<String, dynamic> : {},
        trends: results[1],
        conversionFunnel: results[2],
        userBehavior: results[3],
        batteryHealth: results[4],
        demandForecast: results[5],
        recentActivity: results[6],
        topStations: results[7],
        revenueByRegion: results[8],
        userGrowth: results[9],
        inventoryStatus: results[10],
        revenueByStation: results[11],
        revenueByBatteryType: results[12],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeTrendsPeriod(String period) async {
    state = state.copyWith(trendsPeriod: period);
    try {
      final trends = await _repository.getTrends(period: period);
      state = state.copyWith(trends: trends);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> changeUserGrowthPeriod(String period) async {
    state = state.copyWith(userGrowthPeriod: period);
    try {
      final growth = await _repository.getUserGrowth(period: period);
      state = state.copyWith(userGrowth: growth);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<dynamic> exportReport(String reportType) async {
    try {
      return await _repository.exportReport(reportType: reportType);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref.watch(analyticsRepositoryProvider));
});
