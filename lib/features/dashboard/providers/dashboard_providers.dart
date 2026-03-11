import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_admin/core/api/api_client.dart';
import '../data/analytics_repository.dart';
import '../data/dashboard_models.dart';

// ─────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.read(apiClientProvider));
});

// ─────────────────────────────────────────────
// Auto-refresh mechanism (10-second ticker)
// ─────────────────────────────────────────────

/// Controls whether auto-refresh is paused.
final refreshPausedProvider = StateProvider<bool>((ref) => false);

/// Configurable refresh interval in seconds.
final refreshIntervalProvider = StateProvider<int>((ref) => 10);

/// A ticker that increments every [refreshIntervalProvider] seconds.
/// All data providers depend on this to auto-refresh.
final dashboardRefreshProvider = StreamProvider<int>((ref) async* {
  final isPaused = ref.watch(refreshPausedProvider);
  final intervalSec = ref.watch(refreshIntervalProvider);

  if (isPaused) {
    yield 0;
    return;
  }

  int count = 0;
  while (true) {
    yield count++;
    await Future.delayed(Duration(seconds: intervalSec));
  }
});

/// Tracks the last time data was refreshed successfully.
final lastRefreshTimeProvider = StateProvider<DateTime?>((ref) => null);

// ─────────────────────────────────────────────
// Data providers — each auto-refreshes via ticker
// ─────────────────────────────────────────────

final dashboardOverviewProvider = FutureProvider.autoDispose<DashboardOverview>(
  (ref) async {
    // Subscribe to refresh ticker for auto-refresh
    ref.watch(dashboardRefreshProvider);
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

final trendDataProvider = FutureProvider.autoDispose<TrendData>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(trendPeriodProvider);
  return repo.getTrends(period: period);
});

final conversionFunnelProvider = FutureProvider.autoDispose<ConversionFunnel>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getConversionFunnel();
});

final batteryHealthProvider =
    FutureProvider.autoDispose<BatteryHealthDistribution>((ref) async {
      ref.watch(dashboardRefreshProvider);
      final repo = ref.read(analyticsRepositoryProvider);
      return repo.getBatteryHealthDistribution();
    });

final revenueByRegionProvider = FutureProvider.autoDispose<RevenueByRegion>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getRevenueByRegion();
});

final userGrowthPeriodProvider = StateProvider<String>((ref) => 'monthly');

final userGrowthProvider = FutureProvider.autoDispose<UserGrowth>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final period = ref.watch(userGrowthPeriodProvider);
  return repo.getUserGrowth(period: period);
});

final inventoryStatusProvider = FutureProvider.autoDispose<InventoryStatus>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getInventoryStatus();
});

final demandForecastProvider = FutureProvider.autoDispose<DemandForecast>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getDemandForecast();
});

final userBehaviorProvider = FutureProvider.autoDispose<UserBehavior>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getUserBehavior();
});

final analyticsPeriodProvider = StateProvider<String>((ref) => '30d');

final stationSortProvider = StateProvider<String>((ref) => 'Revenue High-Low');

final revenueByStationProvider = FutureProvider.autoDispose<StationRevenueData>(
  (ref) async {
    ref.watch(dashboardRefreshProvider);
    final repo = ref.read(analyticsRepositoryProvider);
    final period = ref.watch(analyticsPeriodProvider);
    return repo.getRevenueByStation(period: period);
  },
);

final revenueByBatteryTypeProvider =
    FutureProvider.autoDispose<BatteryTypeRevenueData>((ref) async {
      ref.watch(dashboardRefreshProvider);
      final repo = ref.read(analyticsRepositoryProvider);
      final period = ref.watch(analyticsPeriodProvider);
      return repo.getRevenueByBatteryType(period: period);
    });
final recentActivityProvider = FutureProvider.autoDispose<RecentActivityData>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getRecentActivity();
});

final topStationsProvider = FutureProvider.autoDispose<TopStationsData>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopPerformingStations();
});
