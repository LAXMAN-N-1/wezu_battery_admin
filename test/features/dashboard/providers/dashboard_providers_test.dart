import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_admin/core/api/api_client.dart';
import 'package:frontend_admin/features/dashboard/data/analytics_repository.dart';
import 'package:frontend_admin/features/dashboard/data/dashboard_models.dart';
import 'package:frontend_admin/features/dashboard/providers/dashboard_providers.dart';

class _FakeAnalyticsRepository extends AnalyticsRepository {
  _FakeAnalyticsRepository() : super(ApiClient());

  final Completer<DashboardBootstrapData> bootstrapCompleter = Completer();
  int bootstrapCalls = 0;
  int overviewCalls = 0;
  int revenueByRegionCalls = 0;
  int inventoryStatusCalls = 0;
  int topStationsCalls = 0;

  @override
  Future<DashboardBootstrapData> getDashboardBootstrap({
    String period = '30d',
  }) {
    bootstrapCalls++;
    return bootstrapCompleter.future;
  }

  @override
  Future<DashboardOverview> getOverview({String period = '30d'}) async {
    overviewCalls++;
    return DashboardOverview.fromJson(const {});
  }

  @override
  Future<RevenueByRegion> getRevenueByRegion() async {
    revenueByRegionCalls++;
    return RevenueByRegion.fromJson(const {'regions': []});
  }

  @override
  Future<InventoryStatus> getInventoryStatus() async {
    inventoryStatusCalls++;
    return InventoryStatus.fromJson(const {
      'total_batteries': 12,
      'total_available': 4,
      'inventory': [],
    });
  }

  @override
  Future<TopStationsData> getTopPerformingStations() async {
    topStationsCalls++;
    return TopStationsData.fromJson(const {'stations': []});
  }
}

void main() {
  test(
    'revenueByRegionProvider does not block on dashboard bootstrap',
    () async {
      final repo = _FakeAnalyticsRepository();
      final container = ProviderContainer(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(revenueByRegionProvider.future);

      expect(result.regions, isEmpty);
      expect(repo.revenueByRegionCalls, 1);
      expect(repo.bootstrapCalls, 0);
    },
  );

  test(
    'inventoryStatusProvider reads its direct endpoint without bootstrap',
    () async {
      final repo = _FakeAnalyticsRepository();
      final container = ProviderContainer(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(inventoryStatusProvider.future);

      expect(result.totalBatteries, 12);
      expect(repo.inventoryStatusCalls, 1);
      expect(repo.bootstrapCalls, 0);
    },
  );

  test(
    'dashboardOverviewProvider reads the overview endpoint directly',
    () async {
      final repo = _FakeAnalyticsRepository();
      final container = ProviderContainer(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(dashboardOverviewProvider.future);

      expect(repo.overviewCalls, 1);
      expect(repo.bootstrapCalls, 0);
    },
  );

  test(
    'topStationsProvider reads the top stations endpoint directly',
    () async {
      final repo = _FakeAnalyticsRepository();
      final container = ProviderContainer(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(topStationsProvider.future);

      expect(result.stations, isEmpty);
      expect(repo.topStationsCalls, 1);
      expect(repo.bootstrapCalls, 0);
    },
  );
}
