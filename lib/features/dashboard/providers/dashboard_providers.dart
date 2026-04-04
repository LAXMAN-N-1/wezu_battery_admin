import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/analytics_repository.dart';
import '../data/dashboard_models.dart';

// ─────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.read(apiClientProvider)),
);

// Manual refresh trigger; increment to refetch all dashboards.
final dashboardRefreshTriggerProvider = StateProvider<int>((ref) => 0);
final dashboardLightRefreshTriggerProvider = StateProvider<int>((ref) => 0);
final dashboardHeavyRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Tracks the last time data was refreshed successfully.
final lastRefreshTimeProvider = StateProvider<DateTime?>((ref) => null);

void _watchLightRefresh(Ref ref) {
  ref.watch(dashboardRefreshTriggerProvider);
  ref.watch(dashboardLightRefreshTriggerProvider);
}

void _watchHeavyRefresh(Ref ref) {
  ref.watch(dashboardRefreshTriggerProvider);
  ref.watch(dashboardHeavyRefreshTriggerProvider);
}

void _watchAnyRefresh(Ref ref) {
  ref.watch(dashboardRefreshTriggerProvider);
  ref.watch(dashboardLightRefreshTriggerProvider);
  ref.watch(dashboardHeavyRefreshTriggerProvider);
}

final dashboardBootstrapPeriodProvider = Provider<String>((ref) {
  return ref.watch(analyticsPeriodProvider);
});

final dashboardBootstrapProvider = FutureProvider<DashboardBootstrapData>((
  ref,
) async {
  _watchAnyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(dashboardBootstrapPeriodProvider);
  return repo.getDashboardBootstrap(period: period);
});

// ─────────────────────────────────────────────
// Data providers — manually refreshed via dashboardRefreshTriggerProvider
// ─────────────────────────────────────────────

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((
  ref,
) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  DashboardOverview data;
  try {
    final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
    data = bootstrap.overview;
  } catch (_) {
    data = await repo.getOverview();
  }
  Future.microtask(() {
    if (ref.exists(lastRefreshTimeProvider)) {
      ref.read(lastRefreshTimeProvider.notifier).state = DateTime.now();
    }
  });
  return data;
});

final trendPeriodProvider = StateProvider<String>((ref) => '30d');

final trendDataProvider = FutureProvider<TrendData>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(trendPeriodProvider);
  final bootstrapPeriod = ref.watch(dashboardBootstrapPeriodProvider);
  if (period == bootstrapPeriod) {
    try {
      final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
      return bootstrap.trends;
    } catch (_) {}
  }
  return repo.getTrends(period: period);
});

final conversionFunnelProvider = FutureProvider<ConversionFunnel>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  try {
    final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
    return bootstrap.conversionFunnel;
  } catch (_) {
    return repo.getConversionFunnel();
  }
});

final batteryHealthProvider = FutureProvider<BatteryHealthDistribution>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  try {
    final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
    return bootstrap.batteryHealthDistribution;
  } catch (_) {
    return repo.getBatteryHealthDistribution();
  }
});

final revenueByRegionProvider = FutureProvider<RevenueByRegion>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getRevenueByRegion();
});

final userGrowthPeriodProvider = StateProvider<String>((ref) => 'monthly');

final userGrowthProvider = FutureProvider<UserGrowth>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(userGrowthPeriodProvider);
  return repo.getUserGrowth(period: period);
});

final inventoryStatusProvider = FutureProvider<InventoryStatus>((ref) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  try {
    final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
    return bootstrap.inventoryStatus;
  } catch (_) {
    return repo.getInventoryStatus();
  }
});

final demandForecastProvider = FutureProvider<DemandForecast>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  try {
    final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
    return bootstrap.demandForecast;
  } catch (_) {
    return repo.getDemandForecast();
  }
});

final userBehaviorProvider = FutureProvider<UserBehavior>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getUserBehavior();
});

final analyticsPeriodProvider = StateProvider<String>((ref) => '30d');

final stationSortProvider = StateProvider<String>((ref) => 'Revenue High-Low');

final revenueByStationProvider = FutureProvider<StationRevenueData>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(analyticsPeriodProvider);
  final bootstrapPeriod = ref.watch(dashboardBootstrapPeriodProvider);
  if (period == bootstrapPeriod) {
    try {
      final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
      return bootstrap.revenueByStation;
    } catch (_) {}
  }
  return repo.getRevenueByStation(period: period);
});

final revenueByBatteryTypeProvider = FutureProvider<BatteryTypeRevenueData>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(analyticsPeriodProvider);
  return repo.getRevenueByBatteryType(period: period);
});
final activityFilterProvider = StateProvider<String>((ref) => 'all');

final recentActivityProvider = FutureProvider<RecentActivityData>((ref) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final type = ref.watch(activityFilterProvider);
  if (type == 'all') {
    try {
      final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
      return bootstrap.recentActivity;
    } catch (_) {}
  }
  return repo.getRecentActivity(type: type == 'all' ? null : type);
});

final topStationsProvider = FutureProvider<TopStationsData>((ref) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  try {
    final bootstrap = await ref.watch(dashboardBootstrapProvider.future);
    return bootstrap.topStations;
  } catch (_) {
    return repo.getTopPerformingStations();
  }
});

class TrendMetric {
  final String label;
  final String key;
  final Color color;
  final bool isStatic;
  final bool canDelete;

  const TrendMetric({
    required this.label,
    required this.key,
    required this.color,
    this.isStatic = false,
    this.canDelete = false,
  });
}

final trendAvailableMetricsProvider = StateProvider<List<TrendMetric>>((ref) {
  return [
    const TrendMetric(
      label: 'Revenue',
      key: 'revenue',
      color: Color(0xFF06B6D4),
    ),
    const TrendMetric(
      label: 'Rentals',
      key: 'rentals',
      color: Color(0xFFF472B6),
    ),
    const TrendMetric(label: 'Users', key: 'users', color: Colors.purpleAccent),
    const TrendMetric(
      label: 'Battery Health',
      key: 'batteryHealth',
      color: Color(0xFF10B981),
      isStatic: true,
    ),
  ];
});

final trendActiveMetricsProvider = StateProvider<Set<String>>(
  (ref) => {'revenue', 'rentals', 'users', 'batteryHealth'},
);
