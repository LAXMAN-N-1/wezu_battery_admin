import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/models/station_model.dart';
import '../../../core/providers/station_provider.dart';
import '../../../core/widgets/responsive.dart';
import 'station_detail_view.dart';

class StationListView extends ConsumerStatefulWidget {
  const StationListView({super.key});

  @override
  ConsumerState<StationListView> createState() => _StationListViewState();
}

class _StationListViewState extends ConsumerState<StationListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll(StationNotifier notifier) {
    _searchController.clear();
    notifier.setSearchQuery('');
    notifier.setStatusFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stationProvider);
    final notifier = ref.read(stationProvider.notifier);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32),
                child: SectionHeader(
                  title: 'Station Monitoring',
                  action: ElevatedButton.icon(
                    onPressed: () => notifier.loadStations(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ),

              // Analytics Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.count(
                  crossAxisCount: Responsive.isMobile(context) ? 1 : Responsive.isTablet(context) ? 2 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: Responsive.isMobile(context) ? 1.3 : 1.5,
                  children: [
                    StatCard(
                      title: 'Total Stations',
                      value: '${state.stats['total'] ?? 0}',
                      icon: Icons.ev_station,
                      color: AppColors.primary,
                    ),
                    StatCard(
                      title: 'Active (Online)',
                      value: '${state.stats['active'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                    StatCard(
                      title: 'Faulty / Maintenance',
                      value: '${state.stats['faulty'] ?? 0}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                      trend: '-1',
                      trendUp: true,
                    ),
                    StatCard(
                      title: 'Total Swaps Today',
                      value: '${state.stats['total_swaps_today'] ?? 0}',
                      icon: Icons.swap_horiz,
                      color: AppColors.info,
                      trend: '+12%',
                      trendUp: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SearchFilterBar(
                  controller: _searchController,
                  onSearch: (value) => notifier.setSearchQuery(value),
                  onFilterTap: () {},
                  activeFilters: state.statusFilter == null ? const [] : [
                    FilterChip(
                      label: Text(state.statusFilter!.label),
                      selected: true,
                      onSelected: (_) => notifier.setStatusFilter(null),
                      backgroundColor: _getStatusColor(state.statusFilter!).withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: _getStatusColor(state.statusFilter!), fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: _getStatusColor(state.statusFilter!)),
                      ),
                    ),
                  ],
                  onClearFilters: state.statusFilter != null || state.searchQuery.isNotEmpty 
                      ? () => _clearAll(notifier) 
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // Quick Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: state.statusFilter == null,
                      onSelected: (_) => notifier.setStatusFilter(null),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: state.statusFilter == null ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: state.statusFilter == null ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    ),
                    ...StationStatus.values.map((status) {
                      final isSelected = state.statusFilter == status;
                      return FilterChip(
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (selected) => notifier.setStatusFilter(selected ? status : null),
                        backgroundColor: AppColors.surface,
                        selectedColor: _getStatusColor(status).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? _getStatusColor(status) : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? _getStatusColor(status) : AppColors.border,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Station Grid
        state.isLoading
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : state.stations.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        message: 'No stations found',
                        icon: Icons.ev_station_outlined,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.isMobile(context) ? 1 : Responsive.isTablet(context) ? 2 : 3,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final station = state.stations[index];
                          return _StationCard(
                            station: station,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => StationDetailView(station: station)),
                            ),
                          );
                        },
                        childCount: state.stations.length,
                      ),
                    ),
                  ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Color _getStatusColor(StationStatus status) {
    switch (status) {
      case StationStatus.online: return AppColors.success;
      case StationStatus.offline: return AppColors.gray;
      case StationStatus.maintenance: return AppColors.warning;
      case StationStatus.fault: return AppColors.error;
    }
  }
}

class _StationCard extends StatelessWidget {
  final StationModel station;
  final VoidCallback onTap;

  const _StationCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        station.locationAddress,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusDot(station.status),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(Icons.battery_charging_full, '${station.availableBatteries}', 'Available', AppColors.success),
                _buildMetric(Icons.flash_on, '${station.chargingBatteries}', 'Charging', AppColors.warning),
                _buildMetric(Icons.check_box_outline_blank, '${station.emptySlots}', 'Empty', AppColors.textSecondary),
              ],
            ),
            const Spacer(),
            const Divider(color: Color(0x0DFFFFFF)), // Manual constant for AppColors.divider if possible, or just remove const.
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${station.dailySwaps} swaps today',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(StationStatus status) {
    Color color;
    switch (status) {
      case StationStatus.online: color = AppColors.success; break;
      case StationStatus.offline: color = AppColors.gray; break;
      case StationStatus.maintenance: color = AppColors.warning; break;
      case StationStatus.fault: color = AppColors.error; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}
