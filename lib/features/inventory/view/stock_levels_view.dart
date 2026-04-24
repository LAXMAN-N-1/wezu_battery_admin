import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/repositories/stock_repository.dart';
import '../data/models/stock.dart';
import 'station_stock_detail_view.dart';
import '../widgets/stock_map_view.dart';
import '../widgets/reorder_modal.dart';

// Riverpod Providers for this screen
final stockOverviewProvider = FutureProvider.autoDispose<StockOverview>((ref) {
  return ref.watch(stockRepositoryProvider).getOverview();
});

final stockStationsProvider = FutureProvider.autoDispose<List<StationStock>>((
  ref,
) {
  final alertOnly = ref.watch(stockAlertFilterProvider);
  final sortBy = ref.watch(stockSortProvider);
  return ref
      .watch(stockRepositoryProvider)
      .getStations(alertOnly: alertOnly, sortBy: sortBy);
});

final activeAlertsProvider = FutureProvider.autoDispose<List<StockAlert>>((
  ref,
) {
  return ref.watch(stockRepositoryProvider).getAlerts();
});

final stockViewModeProvider = StateProvider<String>(
  (ref) => 'Grid',
); // Grid, List, Map
final stockSortProvider = StateProvider<String>(
  (ref) => 'utilization',
); // utilization, available, name
final stockAlertFilterProvider = StateProvider<bool>(
  (ref) => false,
); // false = all, true = low stock only
final _activeFilterProvider = StateProvider<String>((ref) => 'All Locations');

final stockLocationsProvider = FutureProvider.autoDispose<List<LocationStock>>((
  ref,
) {
  return ref.watch(stockRepositoryProvider).getLocations();
});

class StockLevelsView extends ConsumerWidget {
  const StockLevelsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(stockViewModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stock Levels',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Monitor inventory distribution and restock alerts across all stations',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(children: [_buildViewToggle(ref, viewMode)]),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAlertBanner(context, ref),
                  const SizedBox(height: 24),
                  _buildSummaryCards(ref),
                  const SizedBox(height: 24),
                  _buildFilterBar(ref),
                ],
              ),
            ),
          ),

          // Content Area based on view mode
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: _buildContentArea(ref, viewMode),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildViewToggle(WidgetRef ref, String currentMode) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Grid', 'List', 'Map'].map((mode) {
          final isSelected = currentMode == mode;
          return InkWell(
            onTap: () => ref.read(stockViewModeProvider.notifier).state = mode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    mode == 'Grid'
                        ? Icons.grid_view
                        : (mode == 'List' ? Icons.list : Icons.map),
                    size: 16,
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  if (isSelected) const SizedBox(width: 8),
                  if (isSelected)
                    Text(
                      mode,
                      style: TextStyle(
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(activeAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(
          children: alerts.map((alert) {
            final isCritical = alert.utilizationPercentage < 10;
            final bannerColor = isCritical ? Colors.red : Colors.amber;
            final iconColor = isCritical
                ? Colors.redAccent
                : Colors.amberAccent;
            final label = isCritical ? 'CRITICAL' : 'WARNING';

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Dark slate blue
                  border: Border(
                    left: BorderSide(color: bannerColor, width: 4),
                    top: BorderSide(color: bannerColor.withValues(alpha: 0.3)),
                    right: BorderSide(
                      color: bannerColor.withValues(alpha: 0.3),
                    ),
                    bottom: BorderSide(
                      color: bannerColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bannerColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCritical
                                ? Icons.error_outline
                                : Icons.warning_amber_rounded,
                            color: iconColor,
                            size: 24,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .fade(duration: 1000.ms, begin: 0.5, end: 1.0),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: bannerColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${alert.stationName} has only ${alert.currentCount} battery available (${alert.utilizationPercentage.toInt()}% capacity)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final capturedContext = context;
                        showDialog(
                          context: capturedContext,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          final repo = ref.read(stockRepositoryProvider);
                          final detail = await repo.getStationDetail(
                            alert.stationId,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (capturedContext.mounted) {
                              Navigator.of(capturedContext).pop();
                              showDialog(
                                context: capturedContext,
                                builder: (_) => ReorderModal(
                                  station: detail.station,
                                  forecast: detail.forecast,
                                ),
                              );
                            }
                          });
                        } catch (e) {
                          final msg = e.toString();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (capturedContext.mounted) {
                              Navigator.of(capturedContext).pop();
                              ScaffoldMessenger.of(capturedContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $msg'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      icon: const Text('Create Reorder'),
                      label: const Icon(Icons.arrow_forward, size: 16),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(stockRepositoryProvider)
                            .dismissAlert(
                              alert.stationId,
                              "Dismissed by admin",
                            );
                        ref.invalidate(activeAlertsProvider);
                        ref.invalidate(stockOverviewProvider);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.7),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryCards(WidgetRef ref) {
    final overviewAsync = ref.watch(stockOverviewProvider);

    return overviewAsync.when(
      data: (overview) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: _StatCard(
                  title: 'Fleet Total',
                  subTitle:
                      'Across ${overview.totalStations} stations + ${overview.warehouseCount > 0 || overview.serviceCount > 0 ? "2 locations" : "0 locations"}',
                  value: '${overview.totalBatteries}',
                  icon: Icons.battery_charging_full,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: _StatCard(
                  title: 'Available Now',
                  subTitle:
                      '${overview.totalBatteries > 0 ? (overview.availableCount / overview.totalBatteries * 100).toStringAsFixed(0) : 0}% of fleet ready to rent',
                  value: '${overview.availableCount}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onTap: () => _setSortAndFilter(ref, false, 'available'),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: _StatCard(
                  title: 'In Active Rental',
                  subTitle:
                      'Fleet utilization ${overview.avgUtilization.toStringAsFixed(0)}%',
                  value: '${overview.rentedCount}',
                  icon: Icons.directions_bike,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: _StatCard(
                  title: 'In Service/Maintenance',
                  subTitle:
                      '${overview.maintenanceCount} batteries need attention',
                  value: '${overview.maintenanceCount}',
                  icon: Icons.build,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: _StatCard(
                  title: 'Low Stock Alerts',
                  subTitle: '${overview.lowStockAlerts} stations need reorder',
                  value: '${overview.lowStockAlerts}',
                  icon: Icons.warning_amber_rounded,
                  color: overview.lowStockAlerts > 0
                      ? Colors.red
                      : Colors.green,
                  isAlert: overview.lowStockAlerts > 0,
                  onTap: () => _setSortAndFilter(ref, true, 'utilization'),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error loading stats: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void _setSortAndFilter(WidgetRef ref, bool lowStock, String sort) {
    ref.read(stockAlertFilterProvider.notifier).state = lowStock;
    ref.read(stockSortProvider.notifier).state = sort;
  }

  Widget _buildFilterBar(WidgetRef ref) {
    final sortBy = ref.watch(stockSortProvider);
    // Added new state to track the active filter pill. "All Locations", "Stations Only", "Low Stock", "Critical (<10%)", "Warehouse", "Service Center"
    final activeFilter = ref.watch(_activeFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill(ref, 'All Locations', activeFilter, false),
                  const SizedBox(width: 8),
                  _buildFilterPill(ref, 'Stations Only', activeFilter, false),
                  const SizedBox(width: 8),
                  _buildFilterPill(ref, 'Low Stock', activeFilter, true),
                  const SizedBox(width: 8),
                  _buildFilterPill(ref, 'Critical (<10%)', activeFilter, true),
                  const SizedBox(width: 8),
                  _buildFilterPill(ref, 'Warehouse', activeFilter, false),
                  const SizedBox(width: 8),
                  _buildFilterPill(ref, 'Service Center', activeFilter, false),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'utilization',
                      child: Text('Highest Utilization'),
                    ),
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Lowest Available'),
                    ),
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Alphabetical'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null)
                      ref.read(stockSortProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white54,
                  size: 20,
                ),
                tooltip: 'Updated just now',
                onPressed: () {
                  ref.invalidate(stockOverviewProvider);
                  ref.invalidate(stockStationsProvider);
                  ref.invalidate(activeAlertsProvider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    WidgetRef ref,
    String label,
    String activeFilter,
    bool isAlert,
  ) {
    final isSelected = activeFilter == label;
    final baseColor = isAlert ? Colors.red : const Color(0xFF3B82F6);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(_activeFilterProvider.notifier).state = label;
        // Map to existing API filters
        if (label == 'Low Stock' || label == 'Critical (<10%)') {
          ref.read(stockAlertFilterProvider.notifier).state = true;
        } else {
          ref.read(stockAlertFilterProvider.notifier).state = false;
        }
      },
      backgroundColor: const Color(0xFF0F172A),
      selectedColor: baseColor.withValues(alpha: 0.2),
      checkmarkColor: baseColor,
      labelStyle: TextStyle(
        color: isSelected ? baseColor : Colors.white.withValues(alpha: 0.7),
      ),
      side: BorderSide(
        color: isSelected
            ? baseColor.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildContentArea(WidgetRef ref, String viewMode) {
    if (viewMode == 'Map') {
      return SliverFillRemaining(child: const StockMapView());
    }

    final activeFilter = ref.watch(_activeFilterProvider);
    final stationsAsync = ref.watch(stockStationsProvider);
    final locationsAsync = ref.watch(stockLocationsProvider);

    return stationsAsync.when(
      data: (stations) {
        return locationsAsync.when(
          data: (locations) {
            List<dynamic> items = [];

            if (activeFilter == 'All Locations') {
              items.addAll(stations);
              items.addAll(locations);
            } else if (activeFilter == 'Stations Only' ||
                activeFilter == 'Low Stock') {
              items.addAll(stations);
            } else if (activeFilter == 'Critical (<10%)') {
              items.addAll(stations.where((s) => s.utilizationPercentage < 10));
            } else if (activeFilter == 'Warehouse') {
              items.addAll(
                locations.where((l) => l.locationType == 'WAREHOUSE'),
              );
            } else if (activeFilter == 'Service Center') {
              items.addAll(
                locations.where((l) => l.locationType == 'SERVICE_CENTER'),
              );
            }

            if (items.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No locations match your filters',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              );
            }

            if (viewMode == 'List') {
              return SliverToBoxAdapter(
                child: _buildListView(items, context: ref.context),
              );
            }

            // Grid View
            return SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                mainAxisExtent: 290,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                Widget card;
                if (item is StationStock) {
                  card = _StationStockCard(station: item);
                } else {
                  card = _LocationStockCard(location: item as LocationStock);
                }

                return card
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 30 * index))
                    .slideY(begin: 0.1);
              }, childCount: items.length),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SliverFillRemaining(
            child: Center(
              child: Text(
                'Error loading locations: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SliverFillRemaining(
        child: Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildListView(List<dynamic> items, {required BuildContext context}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFF0F172A).withValues(alpha: 0.5),
        ),
        dataRowMaxHeight: 65,
        dataRowMinHeight: 65,
        columns: const [
          DataColumn(
            label: Text(
              'Station',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Available',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Rented',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Service',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Utilization',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Health',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              '',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
        rows: items.map((item) {
          if (item is StationStock) {
            final s = item;
            final isCritical = s.isLowStock;
            final color = isCritical
                ? Colors.red
                : (s.utilizationPercentage > 70 ? Colors.green : Colors.amber);

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Icon(Icons.storefront, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        s.stationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    '${s.availableCount}',
                    style: TextStyle(
                      color: isCritical ? Colors.redAccent : Colors.white,
                      fontWeight: isCritical
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${s.rentedCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${s.maintenanceCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: s.utilizationPercentage / 100,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.utilizationPercentage.toInt()}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isCritical ? 'LOW STOCK' : 'HEALTHY',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StationStockDetailView(stationId: s.stationId),
                      ),
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ],
            );
          } else if (item is LocationStock) {
            final l = item;
            final color = l.locationType == 'WAREHOUSE'
                ? Colors.blue
                : Colors.purple;
            final icon = l.locationType == 'WAREHOUSE'
                ? Icons.warehouse
                : Icons.build_circle;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        l.locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    '${l.availableCount}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                DataCell(
                  Text(
                    '-',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${l.maintenanceCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '-',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      l.locationType.replaceAll('_', ' '),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  TextButton(onPressed: () {}, child: const Text('Inventory')),
                ),
              ],
            );
          }
          return const DataRow(cells: []);
        }).toList(),
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAlert;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.subTitle,
    required this.value,
    required this.icon,
    required this.color,
    this.isAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            border: Border(
              top: BorderSide(color: color, width: 3),
              left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (isAlert)
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '⚠ ACTION REQ',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationStockCard extends StatelessWidget {
  final StationStock station;

  const _StationStockCard({required this.station});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final isCritical = station.isLowStock;
    final isWarning = station.utilizationPercentage > 85 && !isCritical;
    final statusColor = isCritical
        ? Colors.red
        : (isWarning ? Colors.amber : Colors.green);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                station.stationName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.address,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF334155)),

            // Numbers Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat(
                    'Available',
                    '${station.availableCount}',
                    isCritical ? Colors.redAccent : Colors.white,
                  ),
                  _buildMiniStat(
                    'Rented',
                    '${station.rentedCount}',
                    Colors.white70,
                  ),
                  _buildMiniStat(
                    'Service',
                    '${station.maintenanceCount}',
                    Colors.amber.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),

            // Progress Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${station.utilizationPercentage.toInt()}% utilized',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${station.totalAssigned} total batteries',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        // Rented Segment
                        if (station.totalAssigned > 0)
                          Expanded(
                            flex: station.rentedCount,
                            child: Container(
                              height: 8,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        // Maintenance Segment
                        if (station.totalAssigned > 0)
                          Expanded(
                            flex: station.maintenanceCount,
                            child: Container(height: 8, color: Colors.amber),
                          ),
                        // Available Segment
                        if (station.totalAssigned > 0)
                          Expanded(
                            flex: station.availableCount,
                            child: Container(height: 8, color: Colors.green),
                          ),
                        // Empty slots (based on capacity)
                        if (station.config != null &&
                            station.config!.maxCapacity > station.totalAssigned)
                          Expanded(
                            flex:
                                station.config!.maxCapacity -
                                station.totalAssigned,
                            child: Container(
                              height: 8,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reorder Point: ${station.config?.reorderPoint ?? "N/A"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Just now',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF334155)),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StationStockDetailView(
                            stationId: station.stationId,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                Container(width: 1, height: 50, color: const Color(0xFF334155)),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) => TextButton(
                      onPressed: () async {
                        // Fetch forecast for this station first
                        final capturedContext = context;
                        showDialog(
                          context: capturedContext,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          final repo = ref.read(stockRepositoryProvider);
                          final detail = await repo.getStationDetail(
                            station.stationId,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (capturedContext.mounted) {
                              Navigator.of(capturedContext).pop();
                              showDialog(
                                context: capturedContext,
                                builder: (_) => ReorderModal(
                                  station: detail.station,
                                  forecast: detail.forecast,
                                ),
                              );
                            }
                          });
                        } catch (e) {
                          final msg = e.toString();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (capturedContext.mounted) {
                              Navigator.of(capturedContext).pop();
                              ScaffoldMessenger.of(capturedContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error loading forecast: $msg'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFF3B82F6),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Reorder'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_upward, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LocationStockCard extends StatelessWidget {
  final LocationStock location;

  const _LocationStockCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final isWarehouse = location.locationType == 'WAREHOUSE';
    final statusColor = isWarehouse
        ? const Color(0xFF3B82F6)
        : const Color(0xFFA855F7); // Blue for Warehouse, Purple for Service
    final icon = isWarehouse ? Icons.warehouse : Icons.build_circle;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.locationName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWarehouse
                            ? 'Central Storage Facility'
                            : 'Maintenance & Repair',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isWarehouse ? 'WAREHOUSE' : 'SERVICE',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF334155)),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLargeStat(
                        'Available\nInventory',
                        '${location.availableCount}',
                        Colors.white,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFF334155),
                      ),
                      _buildLargeStat(
                        isWarehouse ? 'In Transit/Prep' : 'In Repair',
                        isWarehouse ? '-' : '${location.maintenanceCount}',
                        isWarehouse ? Colors.white24 : Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFF334155)),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to location inventory
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('View Inventory'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
