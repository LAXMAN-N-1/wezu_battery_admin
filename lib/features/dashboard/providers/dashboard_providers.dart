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

// ─────────────────────────────────────────────
// Data providers — manually refreshed via dashboardRefreshTriggerProvider
// ─────────────────────────────────────────────

final dashboardOverviewProvider = FutureProvider.autoDispose<DashboardOverview>(
  (ref) async {
    _watchLightRefresh(ref);
    final repo = ref.read(analyticsRepositoryProvider);
    final period = ref.watch(analyticsPeriodProvider);
    final data = await repo.getOverview(period: period);
    Future.microtask(() {
      if (ref.exists(lastRefreshTimeProvider)) {
        ref.read(lastRefreshTimeProvider.notifier).state = DateTime.now();
      }
    });
    return data;
  },
);

final trendPeriodProvider = StateProvider<String>((ref) => '30d');

final trendDataProvider = FutureProvider.autoDispose<TrendData>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(trendPeriodProvider);
  return repo.getTrends(period: period);
});

final conversionFunnelProvider = FutureProvider.autoDispose<ConversionFunnel>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getConversionFunnel();
});

final batteryHealthProvider =
    FutureProvider.autoDispose<BatteryHealthDistribution>((ref) async {
      _watchHeavyRefresh(ref);
      final repo = ref.read(analyticsRepositoryProvider);
      return repo.getBatteryHealthDistribution();
    });

final revenueByRegionProvider = FutureProvider.autoDispose<RevenueByRegion>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getRevenueByRegion();
});

final userGrowthPeriodProvider = StateProvider<String>((ref) => 'monthly');

final userGrowthProvider = FutureProvider.autoDispose<UserGrowth>((ref) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(userGrowthPeriodProvider);
  return repo.getUserGrowth(period: period);
});

final inventoryStatusProvider = FutureProvider.autoDispose<InventoryStatus>((
  ref,
) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getInventoryStatus();
});

final demandForecastProvider = FutureProvider.autoDispose<DemandForecast>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getDemandForecast();
});

final userBehaviorProvider = FutureProvider.autoDispose<UserBehavior>((
  ref,
) async {
  _watchHeavyRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getUserBehavior();
});

final analyticsPeriodProvider = StateProvider<String>((ref) => '30d');

final stationSortProvider = StateProvider<String>((ref) => 'Revenue High-Low');

final revenueByStationProvider = FutureProvider.autoDispose<StationRevenueData>(
  (ref) async {
    _watchHeavyRefresh(ref);
    final repo = ref.read(analyticsRepositoryProvider);
    final period = ref.watch(analyticsPeriodProvider);
    return repo.getRevenueByStation(period: period);
  },
);

final revenueByBatteryTypeProvider =
    FutureProvider.autoDispose<BatteryTypeRevenueData>((ref) async {
      _watchHeavyRefresh(ref);
      final repo = ref.read(analyticsRepositoryProvider);
      final period = ref.watch(analyticsPeriodProvider);
      return repo.getRevenueByBatteryType(period: period);
    });
final activityFilterProvider = StateProvider<String>((ref) => 'all');

final recentActivityProvider = FutureProvider.autoDispose<RecentActivityData>((
  ref,
) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  final type = ref.watch(activityFilterProvider);
  return repo.getRecentActivity(type: type == 'all' ? null : type);
});

final topStationsProvider = FutureProvider.autoDispose<TopStationsData>((
  ref,
) async {
  _watchLightRefresh(ref);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopPerformingStations();
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
