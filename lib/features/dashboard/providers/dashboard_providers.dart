import 'dart:async';
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

/// Tracks the last time data was refreshed successfully.
final lastRefreshTimeProvider = StateProvider<DateTime?>((ref) => null);

// ─────────────────────────────────────────────
// Data providers — manually refreshed via dashboardRefreshTriggerProvider
// ─────────────────────────────────────────────

final dashboardOverviewProvider = FutureProvider<DashboardOverview>(
  (ref) async {
    ref.watch(dashboardRefreshTriggerProvider);
    final repo = ref.read(analyticsRepositoryProvider);
    final data = await repo.getOverview();
    Future.microtask(() {
      if (ref.exists(lastRefreshTimeProvider)) {
        ref.read(lastRefreshTimeProvider.notifier).state = DateTime.now();
      }
    });
    return data;
  },
);

final trendPeriodProvider = StateProvider<String>((ref) => 'daily');

final trendDataProvider = FutureProvider<TrendData>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(trendPeriodProvider);
  return repo.getTrends(period: period);
});

final conversionFunnelProvider = FutureProvider<ConversionFunnel>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getConversionFunnel();
});

final batteryHealthProvider =
    FutureProvider<BatteryHealthDistribution>((ref) async {
      ref.watch(dashboardRefreshTriggerProvider);
      final repo = ref.read(analyticsRepositoryProvider);
      return repo.getBatteryHealthDistribution();
    });

final revenueByRegionProvider = FutureProvider<RevenueByRegion>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getRevenueByRegion();
});

final userGrowthPeriodProvider = StateProvider<String>((ref) => 'monthly');

final userGrowthProvider = FutureProvider<UserGrowth>((ref) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(userGrowthPeriodProvider);
  return repo.getUserGrowth(period: period);
});

final inventoryStatusProvider = FutureProvider<InventoryStatus>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getInventoryStatus();
});

final demandForecastProvider = FutureProvider<DemandForecast>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getDemandForecast();
});

final userBehaviorProvider = FutureProvider<UserBehavior>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getUserBehavior();
});

final analyticsPeriodProvider = StateProvider<String>((ref) => '30d');

final stationSortProvider = StateProvider<String>((ref) => 'Revenue High-Low');

final revenueByStationProvider = FutureProvider<StationRevenueData>(
  (ref) async {
    ref.watch(dashboardRefreshTriggerProvider);
    final repo = ref.read(analyticsRepositoryProvider);
    final period = ref.watch(analyticsPeriodProvider);
    return repo.getRevenueByStation(period: period);
  },
);

final revenueByBatteryTypeProvider =
    FutureProvider<BatteryTypeRevenueData>((ref) async {
      ref.watch(dashboardRefreshTriggerProvider);
      final repo = ref.read(analyticsRepositoryProvider);
      final period = ref.watch(analyticsPeriodProvider);
      return repo.getRevenueByBatteryType(period: period);
    });
final activityFilterProvider = StateProvider<String>((ref) => 'all');

final recentActivityProvider = FutureProvider<RecentActivityData>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final type = ref.watch(activityFilterProvider);
  return repo.getRecentActivity(type: type == 'all' ? null : type);
});

final topStationsProvider = FutureProvider<TopStationsData>((
  ref,
) async {
  ref.watch(dashboardRefreshTriggerProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopPerformingStations();
});
