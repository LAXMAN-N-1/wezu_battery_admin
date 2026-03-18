import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/metric_card.dart';
import '../providers/dashboard_providers.dart';
import '../data/dashboard_models.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  String _revenueSort = 'Revenue High-Low';
  bool _showBatteryHealth = false;
  bool _showActiveUsers = false;
  int? _expandedActivity;
  final Set<int> _readActivities = {};
  String _topStationSort = 'rentals_desc';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lastRefresh = ref.watch(lastRefreshTimeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, lastRefresh),
          const SizedBox(height: 24),
          _buildDashboardContent(context, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(
    AppColorsExtension colors,
    DateTime? lastRefresh,
  ) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (lastRefresh != null)
                  Text(
                    'Last updated: ${DateFormat('HH:mm:ss').format(lastRefresh)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                if (lastRefresh != null) const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.info,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Manual refresh',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.info,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-refresh disabled • use Refresh',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildRefreshControls(colors),
      ],
    );
  }

  Widget _buildRefreshControls(AppColorsExtension colors) {
    return Row(
      children: [
        IconButton(
          onPressed: _manualRefreshAll,
          icon: Icon(Icons.refresh_outlined, color: colors.textSecondary),
          tooltip: 'Refresh data',
        ),
      ],
    );
  }

  void _manualRefreshAll() {
    // bump trigger to force refresh of all dashboard providers
    ref.read(dashboardRefreshTriggerProvider.notifier).state++;
    ref.invalidate(dashboardOverviewProvider);
    ref.invalidate(trendDataProvider);
    ref.invalidate(conversionFunnelProvider);
    ref.invalidate(batteryHealthProvider);
    ref.invalidate(revenueByRegionProvider);
    ref.invalidate(revenueByStationProvider);
    ref.invalidate(revenueByBatteryTypeProvider);
    ref.invalidate(recentActivityProvider);
    ref.invalidate(topStationsProvider);
    ref.invalidate(userGrowthProvider);
    ref.invalidate(userBehaviorProvider);
    ref.invalidate(inventoryStatusProvider);
    ref.invalidate(demandForecastProvider);
    ref.read(lastRefreshTimeProvider.notifier).state = DateTime.now();
  }

  Widget _buildDashboardContent(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Primary KPI Grid (Metrics)
        _buildKPIGrid(context, colors),

        const SizedBox(height: 32),

        // 2. Trend Analysis & Station Health (Middle Row)
        if (screenWidth > 1200)
          SizedBox(
            height: 480,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildTrendsChart(colors)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildBatteryHealthDonut(colors)),
              ],
            ),
          )
        else
          Column(
            children: [
              SizedBox(height: 480, child: _buildTrendsChart(colors)),
              const SizedBox(height: 24),
              SizedBox(height: 480, child: _buildBatteryHealthDonut(colors)),
            ],
          ),

        const SizedBox(height: 32),

        // 3. Analytics Grid (Revenue & Recent Activity)
        if (screenWidth > 1200)
          SizedBox(
            height: 500,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildRevenueAnalyticsCard(colors)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildRecentActivityCard(colors)),
              ],
            ),
          )
        else
          Column(
            children: [
              SizedBox(height: 500, child: _buildRevenueAnalyticsCard(colors)),
              const SizedBox(height: 24),
              SizedBox(height: 500, child: _buildRecentActivityCard(colors)),
            ],
          ),

        const SizedBox(height: 32),

        // 4. Top Stations & Funnel
        if (screenWidth > 1200)
          SizedBox(
            height: 600,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildTopStationsCard(colors)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildFunnelCard(colors)),
              ],
            ),
          )
        else
          Column(
            children: [
              _buildTopStationsCard(colors),
              const SizedBox(height: 24),
              SizedBox(height: 500, child: _buildFunnelCard(colors)),
            ],
          ),

        const SizedBox(height: 32),

        // 5. Operations & Forecasts
        if (screenWidth > 1200)
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _buildInventoryCard(colors)),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildForecastCard(colors)),
              ],
            ),
          )
        else
          Column(
            children: [
              SizedBox(height: 400, child: _buildInventoryCard(colors)),
              const SizedBox(height: 24),
              SizedBox(height: 400, child: _buildForecastCard(colors)),
            ],
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildKPIGrid(BuildContext context, AppColorsExtension colors) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400
        ? 6
        : screenWidth > 1000
        ? 3
        : screenWidth > 600
        ? 2
        : 1;

    return overviewAsync.when(
      data: (data) => GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            key: const ValueKey('metric_revenue'),
            title: 'Total Revenue',
            value: _formatCurrency(data.totalRevenue.value),
            subtitle: 'This month',
            trend: '${data.totalRevenue.changePercent >= 0 ? '+' : ''}${data.totalRevenue.changePercent.toStringAsFixed(1)}%',
            trendLabel: 'vs last month',
            icon: Icons.currency_rupee,
            color: colors.success,
            sparkData: data.totalRevenue.sparkline,
            changeValue: data.totalRevenue.changePercent,
          ),
          MetricCard(
            key: const ValueKey('metric_rentals'),
            title: 'Total Rentals',
            value: data.activeRentals.value.toString(),
            subtitle: 'This month',
            trend: '${data.activeRentals.changePercent >= 0 ? '+' : ''}${data.activeRentals.changePercent.toStringAsFixed(1)}%',
            trendLabel: 'vs last month',
            icon: Icons.electric_scooter,
            color: colors.accent,
            sparkData: data.activeRentals.sparkline,
            changeValue: data.activeRentals.changePercent,
          ),
          MetricCard(
            key: const ValueKey('metric_users'),
            title: 'Active Users',
            value: data.totalUsers.value.toString(),
            subtitle: 'Right now',
            trend: '${data.totalUsers.changePercent >= 0 ? '+' : ''}${data.totalUsers.changePercent.toStringAsFixed(1)}%',
            trendLabel: 'vs last month',
            icon: Icons.people_outline,
            color: colors.secondary,
            sparkData: data.totalUsers.sparkline,
            changeValue: data.totalUsers.changePercent,
          ),
          MetricCard(
            key: const ValueKey('metric_utilization'),
            title: 'Fleet Utilization',
            value: '${data.fleetUtilization.value}%',
            subtitle: 'Battery fleet',
            trend: '${data.fleetUtilization.changePercent >= 0 ? '+' : ''}${data.fleetUtilization.changePercent.toStringAsFixed(1)}%',
            trendLabel: 'vs last month',
            icon: Icons.battery_charging_full,
            color: colors.warning,
            sparkData: data.fleetUtilization.sparkline,
            changeValue: data.fleetUtilization.changePercent,
          ),
          MetricCard(
            key: const ValueKey('metric_rev_per_rental'),
            title: 'Rev / Rental',
            value: _formatCurrency(data.revenuePerRental.value),
            subtitle: 'This month efficiency',
            trend: '${data.revenuePerRental.changePercent >= 0 ? '+' : ''}${data.revenuePerRental.changePercent.toStringAsFixed(1)}%',
            trendLabel: 'vs last month',
            icon: Icons.point_of_sale_outlined,
            color: colors.info,
            sparkData: data.revenuePerRental.sparkline,
            changeValue: data.revenuePerRental.changePercent,
          ),
          MetricCard(
            key: const ValueKey('metric_avg_session'),
            title: 'Avg. Session',
            value: '${data.avgSessionDuration.value}m',
            subtitle: 'Duration per rental',
            trend: '${data.avgSessionDuration.changePercent >= 0 ? '+' : ''}${data.avgSessionDuration.changePercent.toStringAsFixed(1)}%',
            trendLabel: 'vs last month',
            icon: Icons.timer_outlined,
            color: colors.textSecondary,
            sparkData: data.avgSessionDuration.sparkline,
            changeValue: data.avgSessionDuration.changePercent,
          ),
        ],
      ),
      loading: () => GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          6,
          (index) => MetricCard(
            key: ValueKey('metric_loading_$index'),
            title: '',
            value: '',
            subtitle: '',
            trend: '',
            trendLabel: '',
            icon: Icons.hourglass_empty,
            color: colors.border,
            isLoading: true,
          ),
        ),
      ),
      error: (e, s) => Center(child: Text('Error loading metrics: $e')),
    );
  }

  Widget _buildTrendsChart(AppColorsExtension colors) {
    final trendsAsync = ref.watch(trendDataProvider);

    return Container(
      height: 480,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend Analysis',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last 30 days performance',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildExportButton(colors),
              const SizedBox(width: 12),
              _buildPeriodToggle(colors),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartLegend(colors),
          const SizedBox(height: 32),
          Expanded(
            child: trendsAsync.when(
              data: (data) => _buildTrendGraph(data, colors),
              loading: () => trendsAsync.hasValue
                  ? _buildTrendGraph(trendsAsync.value!, colors)
                  : const Center(child: CircularProgressIndicator()),
              error: (e, s) => trendsAsync.hasValue
                  ? _buildTrendGraph(trendsAsync.value!, colors)
                  : Center(child: Text('Error loading trends: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(AppColorsExtension colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendItem('Revenue (₹)', colors.accent, colors, isActive: true),
        _legendItem('Rentals', colors.secondary, colors, isActive: true),
        const SizedBox(width: 16),
        Container(height: 16, width: 1, color: colors.border),
        const SizedBox(width: 16),
        Text('Overlays:', style: GoogleFonts.inter(color: colors.textTertiary, fontSize: 12)),
        _toggleItem('Active Users', const Color(0xFF9C27B0), _showActiveUsers, (v) => setState(() => _showActiveUsers = v), colors),
        _toggleItem('Battery Health', colors.success, _showBatteryHealth, (v) => setState(() => _showBatteryHealth = v), colors),
      ],
    );
  }

  Widget _legendItem(String label, Color color, AppColorsExtension colors, {bool isActive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _toggleItem(String label, Color color, bool value, ValueChanged<bool> onChanged, AppColorsExtension colors) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: value ? color.withValues(alpha: 0.5) : colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_circle : Icons.circle_outlined, size: 14, color: value ? color : colors.textTertiary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: value ? color : colors.textSecondary, fontWeight: value ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(AppColorsExtension colors) {
    final period = ref.watch(trendPeriodProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.scaffoldBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Today', '7D', '30D', '90D', 'Custom'].map((p) {
          final isSelected = p == period;
          return GestureDetector(
            onTap: () => ref.read(trendPeriodProvider.notifier).state = p,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                p.capitalize(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportButton(AppColorsExtension colors) {
    return PopupMenuButton<String>(
      color: colors.cardBg,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      position: PopupMenuPosition.under,
      tooltip: 'Export',
      onSelected: (v) {
        // Hook into export API; for now simply refresh.
        ref.invalidate(trendDataProvider);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'csv', child: Text('CSV')),
        const PopupMenuItem(value: 'png', child: Text('PNG')),
        const PopupMenuItem(value: 'pdf', child: Text('PDF')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.scaffoldBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_outlined,
              size: 18,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Export',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendGraph(TrendData data, AppColorsExtension colors) {
    if (data.points.length < 2) return const Center(child: Text('Not enough trend data'));

    final revenueMax = data.points
        .map((e) => e.revenue)
        .fold<double>(0, (prev, element) => element > prev ? element : prev);
    final rentalsMax = data.points
        .map((e) => e.rentals)
        .fold<double>(0, (prev, element) => element > prev ? element : prev);
    final usersMax = data.points
        .map((e) => e.users)
        .fold<double>(0, (prev, element) => element > prev ? element : prev);

    final revenueSpots = data.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value.revenue))
        .toList();
    final rentalsScale =
        (revenueMax > 0 && rentalsMax > 0) ? revenueMax / rentalsMax : 1;
    final rentalsSpots = data.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value.rentals * rentalsScale))
        .toList();
    final usersScale =
        (revenueMax > 0 && usersMax > 0) ? revenueMax / usersMax : rentalsScale;
    final usersSpots = data.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value.users * usersScale))
        .toList();
    final healthScale = revenueMax > 0 ? revenueMax / 100 : 1;
    final healthSpots = data.points
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble() + 1, e.value.batteryHealth * healthScale))
        .toList();

    final double horizontalInterval = revenueMax > 0
        ? (revenueMax / 5).clamp(1000, double.infinity).toDouble()
        : 3000.0;

    return LineChart(
      key: const ValueKey('dashboard_main_trends_chart'),
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (value) => FlLine(color: colors.border.withValues(alpha: 0.2), strokeWidth: 1, dashArray: [5, 5]),
          getDrawingVerticalLine: (value) => FlLine(color: colors.border.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final rentalsValue =
                    rentalsScale == 0 ? 0 : value / rentalsScale;
                if (rentalsValue.isNaN || rentalsValue.isInfinite) {
                  return const SizedBox();
                }
                return Text(
                  rentalsValue.toStringAsFixed(0),
                  style: GoogleFonts.inter(
                    color: colors.secondary,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0 && value != 1) return const SizedBox();
                final day = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Day $day', style: GoogleFonts.inter(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: horizontalInterval,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(_compactNumber(value), style: GoogleFonts.inter(color: colors.accent, fontSize: 11));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _createTrendLine(revenueSpots, colors.accent, isPrimary: true),
          _createTrendLine(rentalsSpots, colors.secondary),
          if (_showActiveUsers)
            _createTrendLine(usersSpots, const Color(0xFF9C27B0)),
          if (_showBatteryHealth)
            _createTrendLine(healthSpots, colors.success),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.cardBg,
            tooltipBorder: BorderSide(color: colors.border),
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];
              final index = touchedSpots.first.x.toInt() - 1;
              if (index < 0 || index >= data.points.length) return [];
              final p = data.points[index];
              return [
                LineTooltipItem(
                  'Day ${index + 1}\n',
                  GoogleFonts.outfit(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: 'Revenue: ${_formatCurrency(p.revenue)}\n',
                      style: TextStyle(color: colors.accent, fontSize: 11),
                    ),
                    TextSpan(
                      text: 'Rentals: ${p.rentals.toStringAsFixed(0)}\n',
                      style: TextStyle(color: colors.secondary, fontSize: 11),
                    ),
                    if (_showActiveUsers)
                      TextSpan(
                        text: 'Active Users: ${p.users.toStringAsFixed(0)}\n',
                        style:
                            TextStyle(color: const Color(0xFF9C27B0), fontSize: 11),
                      ),
                    if (_showBatteryHealth)
                      TextSpan(
                        text:
                            'Battery Health: ${p.batteryHealth.toStringAsFixed(1)}%',
                        style: TextStyle(color: colors.success, fontSize: 11),
                      ),
                  ],
                ),
              ];
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _createTrendLine(
    List<FlSpot> spots,
    Color color, {
    bool isPrimary = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: isPrimary ? 4 : 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: isPrimary,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  Widget _buildBatteryHealthDonut(AppColorsExtension colors) {
    final healthAsync = ref.watch(batteryHealthProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Station Health',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Icon(Icons.more_horiz, color: colors.textSecondary),
            ],
          ),
          Text(
            'Network status & worst performers',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: healthAsync.when(
              data: (data) => _buildStationHealthSplit(data, colors),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationHealthSplit(BatteryHealthDistribution data, AppColorsExtension colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Half: Donut
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(child: _buildDonutChartOnly(data, colors)),
              const SizedBox(height: 16),
              // Geographic Heatmap Thumbnail (Mock)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.accent.withValues(alpha: 0.08),
                      colors.secondary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Stack(
                  children: [
                    ...List.generate(8, (i) {
                      final left = (i * 12 + 8).toDouble();
                      final top = (i * 6 + 10).toDouble();
                      final color = i % 3 == 0
                          ? colors.success
                          : (i % 3 == 1 ? colors.accent : colors.danger);
                      return Positioned(
                        left: left,
                        top: top,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Geo Health Map',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Container(width: 1, color: colors.border),
        const SizedBox(width: 24),
        // Right Half: 5 Worst Stations
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Needs Attention',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) => Divider(color: colors.border.withValues(alpha: 0.5), height: 24),
                  itemBuilder: (context, index) {
                    final names = ['Korattur Hub', 'Anna Nagar West', 'T-Nagar Depo', 'Velachery Main', 'Guindy Station'];
                    final scores = [45, 52, 58, 61, 65];
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: colors.danger, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(names[index], style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary, fontSize: 13)),
                              Text('Health Score: ${scores[index]}', style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary)),
                            ],
                          ),
                        ),
                        Icon(Icons.trending_down, size: 16, color: colors.danger),
                        const SizedBox(width: 12),
                        Text(
                          'View',
                          style: GoogleFonts.inter(fontSize: 12, color: colors.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChartOnly(BatteryHealthDistribution data, AppColorsExtension colors) {
    final currentSections = data.buckets.map((b) {
      final color = _healthColor(b.category);
      return PieChartSectionData(
        value: b.percentage,
        title: '',
        color: color,
        radius: 80,
        showTitle: false,
        badgeWidget: null,
      );
    }).toList();

    final previousSections = data.previousBuckets.isNotEmpty
        ? data.previousBuckets.map((b) {
            final color = _healthColor(b.category).withValues(alpha: 0.35);
            return PieChartSectionData(
              value: b.percentage,
              title: '',
              color: color,
              radius: 60,
              showTitle: false,
            );
          }).toList()
        : <PieChartSectionData>[];

    final total = data.totalBatteries;
    final previousTotal = data.previousTotal != 0 ? data.previousTotal : total;
    final delta = total - previousTotal;
    final deltaColor = delta >= 0 ? colors.success : colors.danger;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (previousSections.isNotEmpty)
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    sections: previousSections,
                    startDegreeOffset: 270,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              PieChart(
                key: const ValueKey('station_health_donut'),
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 70,
                  sections: currentSections,
                  startDegreeOffset: 270,
                  borderData: FlBorderData(show: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NumberFormat('#,###').format(total),
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta == 0
                            ? Icons.drag_handle_rounded
                            : delta > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                        size: 14,
                        color: delta == 0 ? colors.textTertiary : deltaColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${delta >= 0 ? '+' : ''}$delta vs last week',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: delta == 0 ? colors.textTertiary : deltaColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: data.buckets.map((b) {
            final color = _healthColor(b.category);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b.category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${b.percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _healthColor(String category) {
    if (category.toLowerCase().contains('excellent')) {
      return const Color(0xFF22C55E);
    } else if (category.toLowerCase().contains('good')) {
      return const Color(0xFFF59E0B);
    } else if (category.toLowerCase().contains('fair')) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFFEF4444);
  }

  Widget _buildFunnelCard(AppColorsExtension colors) {
    final funnelAsync = ref.watch(conversionFunnelProvider);
    return _buildAnalyticsContainer(
      title: 'Conversion Funnel',
      subtitle: 'User journey & drop-off analysis',
      colors: colors,
      child: funnelAsync.when(
        data: (data) => _buildFunnelWidget(data, colors),
        loading: () => funnelAsync.hasValue
            ? _buildFunnelWidget(funnelAsync.value!, colors)
            : const Center(child: CircularProgressIndicator()),
        error: (e, s) => funnelAsync.hasValue
            ? _buildFunnelWidget(funnelAsync.value!, colors)
            : Text('Error: $e'),
      ),
    );
  }

  Widget _buildFunnelWidget(ConversionFunnel data, AppColorsExtension colors) {
    if (data.stages.isEmpty) return const Center(child: Text('No funnel data'));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.stages.length,
      separatorBuilder: (context, index) {
        final stage = data.stages[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Icon(Icons.arrow_downward, size: 14, color: colors.danger),
              const SizedBox(width: 8),
              Text(
                '${stage.dropOffRate.toStringAsFixed(1)}% drop-off',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      itemBuilder: (context, index) {
        final stage = data.stages[index];
        final totalCount = data.stages.first.count;
        final percentage = totalCount > 0
            ? (stage.count / totalCount) * 100
            : 0;

        Color stageColor;
        switch (index % 4) {
          case 0:
            stageColor = colors.accent;
            break;
          case 1:
            stageColor = colors.secondary;
            break;
          case 2:
            stageColor = Colors.orange;
            break;
          case 3:
            stageColor = colors.success;
            break;
          default:
            stageColor = colors.accent;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stage.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: stage.count.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' (${percentage.toInt()}%)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 10,
                      width: constraints.maxWidth * (percentage / 100),
                      decoration: BoxDecoration(
                        color: stageColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: stageColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInventoryCard(AppColorsExtension colors) {
    final inventoryAsync = ref.watch(inventoryStatusProvider);
    return _buildAnalyticsContainer(
      title: 'Inventory Snapshot',
      subtitle: 'Availability by battery type',
      colors: colors,
      child: inventoryAsync.when(
        data: (data) {
          if (data.items.isEmpty) {
            return const Center(child: Text('No inventory data'));
          }
          final topItems = data.items.take(5).toList();
          final utilization = data.totalBatteries > 0
              ? ((data.totalBatteries - data.totalAvailable) / data.totalBatteries * 100)
              : 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _inventoryStat('Total', data.totalBatteries.toString(), colors.textPrimary, colors),
                  const SizedBox(width: 16),
                  _inventoryStat('Available', data.totalAvailable.toString(), colors.success, colors),
                  const SizedBox(width: 16),
                  _inventoryStat('Utilization', '${utilization.toStringAsFixed(1)}%', colors.accent, colors),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: topItems.length,
                  separatorBuilder: (_, __) => Divider(color: colors.border.withValues(alpha: 0.4)),
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    final inUse = item.rented;
                    final percentAvailable = item.total == 0 ? 0 : (item.available / item.total * 100);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.category, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                            Text('${item.total} units', style: GoogleFonts.inter(color: colors.textTertiary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: item.total == 0 ? 0 : inUse / item.total,
                            minHeight: 8,
                            backgroundColor: colors.border.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation(colors.accent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentAvailable.toStringAsFixed(1)}% available • ${inUse} in use',
                          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  Widget _inventoryStat(String label, String value, Color color, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _buildForecastCard(AppColorsExtension colors) {
    final forecastAsync = ref.watch(demandForecastProvider);
    return _buildAnalyticsContainer(
      title: '7-Day Demand Forecast',
      subtitle: 'Predicted rentals vs actuals',
      colors: colors,
      child: forecastAsync.when(
        data: (data) => _buildForecastChart(data, colors),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  Widget _buildForecastChart(DemandForecast data, AppColorsExtension colors) {
    if (data.points.length < 2) {
      return const Center(child: Text('Not enough forecast data'));
    }
    final predictedSpots = data.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.predicted))
        .toList();
    final actualSpots = data.points
        .asMap()
        .entries
        .where((e) => e.value.actual != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.actual!))
        .toList();
    final maxY = [
      ...predictedSpots.map((e) => e.y),
      ...actualSpots.map((e) => e.y),
    ].fold<double>(0, (prev, val) => val > prev ? val : prev) *
        1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: math.max(1, maxY / 4),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.border.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.points.length) return const SizedBox();
                final label = data.points[idx].date.split('-').last;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _createTrendLine(predictedSpots, colors.accent, isPrimary: true),
          if (actualSpots.isNotEmpty) _createTrendLine(actualSpots, colors.success),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.cardBg,
            tooltipBorder: BorderSide(color: colors.border),
          ),
        ),
        minY: 0,
        maxY: maxY <= 0 ? 10 : maxY,
      ),
    );
  }

  Widget _buildRevenueAnalyticsCard(AppColorsExtension colors) {
    final revenueAsync = ref.watch(revenueByRegionProvider);
    return _buildAnalyticsContainer(
      title: 'Revenue Analytics',
      subtitle: 'Revenue distribution by station',
      colors: colors,
      child: revenueAsync.when(
        data: (data) => _buildRevenueChart(data, colors),
        loading: () => revenueAsync.hasValue
            ? _buildRevenueChart(revenueAsync.value!, colors)
            : const Center(child: CircularProgressIndicator()),
        error: (e, s) => revenueAsync.hasValue
            ? _buildRevenueChart(revenueAsync.value!, colors)
            : Text('Error: $e'),
      ),
    );
  }

  Widget _buildRevenueChart(RevenueByRegion data, AppColorsExtension colors) {
    // Sort data based on selected sort option
    List<RegionRevenue> sortedRegions = List.from(data.regions);
    if (_revenueSort == 'Revenue High-Low') {
      sortedRegions.sort((a, b) => b.revenue.compareTo(a.revenue));
    } else if (_revenueSort == 'Revenue Low-High') {
      sortedRegions.sort((a, b) => a.revenue.compareTo(b.revenue));
    } else if (_revenueSort == 'Sort by Name') {
      sortedRegions.sort((a, b) => a.region.compareTo(b.region));
    } else if (_revenueSort == 'Sort by Volume') {
      sortedRegions.sort((a, b) => b.rentalCount.compareTo(a.rentalCount));
    }

    // Filter by tab (this is mocked here as the API currently only returns regions)
    // In a real app, the API would take station/battery as a parameter
    final displayData = sortedRegions.take(6).toList();

    final maxY = displayData.isEmpty
        ? 1.0
        : math.max(
            displayData
                    .map((e) => e.revenue)
                    .reduce((a, b) => a > b ? a : b) *
                1.2,
            1.0,
          );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRevenueSortDropdown(colors),
            _buildRevenueToggle(colors),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BarChart(
            key: const ValueKey('revenue_bar_chart'),
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colors.cardBg,
                  tooltipBorder: BorderSide(color: colors.border),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${displayData[groupIndex].region}\n',
                      GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: _formatCurrency(rod.toY),
                          style: TextStyle(color: colors.success),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < displayData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            displayData[index].region.length > 3
                                ? displayData[index].region
                                      .substring(0, 3)
                                      .toUpperCase()
                                : displayData[index].region.toUpperCase(),
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _compactNumber(value),
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colors.border.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: displayData.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.revenue,
                      color: e.key % 5 == 0
                          ? const Color(0xFF22D3EE) // Cyan
                          : e.key % 5 == 1
                          ? const Color(0xFFA855F7) // Purple
                          : e.key % 5 == 2
                          ? const Color(0xFF22C55E) // Green
                          : e.key % 5 == 3
                          ? const Color(0xFFFBBF24) // Yellow
                          : const Color(0xFFF97316), // Orange
                      width: 28,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: colors.border.withValues(alpha: 0.03),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueToggle(AppColorsExtension colors) {
    return const SizedBox.shrink(); // Batteries button removed as per user request
  }

  Widget _buildRecentActivityCard(AppColorsExtension colors) {
    final activityAsync = ref.watch(recentActivityProvider);
    return _buildLiveAnalyticsContainer(
      title: 'Recent Activity',
      colors: colors,
      child: activityAsync.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                _activityFilterChip('all', 'All', colors),
                _activityFilterChip('rental', 'Rentals', colors,
                    accent: colors.accent),
                _activityFilterChip('alert', 'Alerts', colors,
                    accent: colors.danger),
                _activityFilterChip('system', 'System', colors),
                _activityFilterChip('user', 'User Actions', colors,
                    accent: colors.success),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _readActivities.clear()),
                icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                label: const Text('Mark all read'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: colors.textSecondary,
                ),
              ),
            ),
            Expanded(child: _buildActivityList(data, colors)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  Widget _activityFilterChip(String key, String label, AppColorsExtension colors, {Color? accent}) {
    final selected = ref.watch(activityFilterProvider);
    final isSelected = selected == key;
    final chipColor = accent ?? colors.textSecondary;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      labelStyle: TextStyle(color: isSelected ? Colors.white : colors.textSecondary),
      selectedColor: chipColor,
      backgroundColor: colors.scaffoldBg.withValues(alpha: 0.4),
      onSelected: (_) => ref.read(activityFilterProvider.notifier).state = key,
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
    );
  }

  Widget _buildActivityList(
    RecentActivityData data,
    AppColorsExtension colors,
  ) {
    final filtered = data.activities;

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        IconData iconData;
        Color iconColor;

        switch (item.type) {
          case 'user':
            iconData = Icons.person_add_outlined;
            iconColor = colors.success;
            break;
          case 'rental':
            iconData = Icons.electric_scooter_outlined;
            iconColor = colors.accent;
            break;
          case 'swap':
            iconData = Icons.swap_horiz_outlined;
            iconColor = colors.secondary;
            break;
          case 'payment':
            iconData = Icons.payments_outlined;
            iconColor = Colors.orange;
            break;
          case 'alert':
            iconData = Icons.warning_amber_outlined;
            iconColor = colors.danger;
            break;
          default:
            iconData = Icons.notifications_none_outlined;
            iconColor = colors.textSecondary;
        }

        final isExpanded = _expandedActivity == index;
        final isRead = _readActivities.contains(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: InkWell(
            onTap: () => setState(() {
              _expandedActivity = isExpanded ? null : index;
              _readActivities.add(index);
            }),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRead ? colors.border : iconColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(iconData, size: 20, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item.severity == 'critical'
                                      ? colors.danger
                                      : colors.textSecondary)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: item.severity == 'critical'
                                    ? colors.danger
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.time,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (isExpanded && item.details.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.scaffoldBg.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.details.entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${e.key}: ',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            e.value.toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopStationsCard(AppColorsExtension colors) {
    final stationsAsync = ref.watch(topStationsProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Performing Stations',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => GoRouter.of(context).go('/stations/performance'),
                child: Text(
                  'View All',
                  style: TextStyle(color: colors.accent, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          stationsAsync.when(
            data: (data) => _buildStationsTable(data, colors),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildStationsTable(TopStationsData data, AppColorsExtension colors) {
    List<TopStation> stations = List.from(data.stations);
    bool ascending = true;
    int? sortColumnIndex;

    switch (_topStationSort) {
      case 'rentals_desc':
        stations.sort((a, b) => b.rentals.compareTo(a.rentals));
        sortColumnIndex = 2;
        ascending = false;
        break;
      case 'rentals_asc':
        stations.sort((a, b) => a.rentals.compareTo(b.rentals));
        sortColumnIndex = 2;
        break;
      case 'revenue_desc':
        stations.sort((a, b) => b.revenue.compareTo(a.revenue));
        sortColumnIndex = 3;
        ascending = false;
        break;
      case 'revenue_asc':
        stations.sort((a, b) => a.revenue.compareTo(b.revenue));
        sortColumnIndex = 3;
        break;
      case 'utilization_desc':
        stations.sort((a, b) => b.utilization.compareTo(a.utilization));
        sortColumnIndex = 4;
        ascending = false;
        break;
      case 'utilization_asc':
        stations.sort((a, b) => a.utilization.compareTo(b.utilization));
        sortColumnIndex = 4;
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 32,
        horizontalMargin: 0,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 52,
        sortColumnIndex: sortColumnIndex,
        sortAscending: ascending,
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.textTertiary,
        ),
        columns: [
          const DataColumn(label: Text('Rank')),
          const DataColumn(label: Text('Location')),
          DataColumn(
            label: const Text('Rentals'),
            onSort: (_, __) {
              setState(() {
                _topStationSort = _topStationSort.startsWith('rentals') &&
                        _topStationSort.endsWith('desc')
                    ? 'rentals_asc'
                    : 'rentals_desc';
              });
            },
          ),
          DataColumn(
            label: const Text('Revenue'),
            onSort: (_, __) {
              setState(() {
                _topStationSort = _topStationSort.startsWith('revenue') &&
                        _topStationSort.endsWith('desc')
                    ? 'revenue_asc'
                    : 'revenue_desc';
              });
            },
          ),
          DataColumn(
            label: const Text('Utilization'),
            onSort: (_, __) {
              setState(() {
                _topStationSort = _topStationSort.startsWith('utilization') &&
                        _topStationSort.endsWith('desc')
                    ? 'utilization_asc'
                    : 'utilization_desc';
              });
            },
          ),
          const DataColumn(label: Text('Rating')),
        ],
        rows: stations.asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      padding: const EdgeInsets.all(8),
                      // Flutter Tooltip asserts that exactly one of message or
                      // richMessage is non-null. Show the mini sparkline when
                      // data exists, otherwise fall back to a plain text label.
                      message: s.sparkline.length < 2
                          ? (s.name.isNotEmpty ? s.name : s.id)
                          : null,
                      richMessage: s.sparkline.length < 2
                          ? null
                          : TextSpan(
                              children: [
                                WidgetSpan(
                                  child: SizedBox(
                                    width: 160,
                                    height: 60,
                                    child: LineChart(
                                      LineChartData(
                                        titlesData:
                                            const FlTitlesData(show: false),
                                        gridData:
                                            const FlGridData(show: false),
                                        borderData:
                                            FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: s.sparkline
                                                .asMap()
                                                .entries
                                                .map((e) => FlSpot(
                                                    e.key.toDouble(),
                                                    e.value))
                                                .toList(),
                                            isCurved: true,
                                            color: colors.accent,
                                            barWidth: 3,
                                            dotData:
                                                const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: colors.accent
                                                  .withValues(alpha: 0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      child: Text(
                        s.name.isNotEmpty ? s.name : s.id,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(
                  s.location.isNotEmpty ? s.location : s.name,
                  style: const TextStyle(fontSize: 13))),
              DataCell(
                Text(
                  NumberFormat('#,###').format(s.rentals),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DataCell(
                Text(
                  _formatCurrency(s.revenue),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.success,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: s.utilization <= 0
                                    ? 1
                                    : s.utilization.clamp(1, 100).toInt(),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.success,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: (() {
                                  final val = s.chargingPercent > 0
                                      ? s.chargingPercent
                                      : 100 - s.utilization - s.offlinePercent;
                                  return val <= 0 ? 1 : val.clamp(1, 100).toInt();
                                })(),
                                child: Container(
                                  height: 8,
                                  color: colors.accent.withValues(alpha: 0.6),
                                ),
                              ),
                              Expanded(
                                flex: s.offlinePercent <= 0
                                    ? 1
                                    : s.offlinePercent.clamp(1, 100).toInt(),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.textTertiary.withValues(alpha: 0.4),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${s.utilization.toInt()}% active',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const Spacer(),
                          Text(
                            '${s.availablePercent.toInt()}% avail',
                            style: TextStyle(fontSize: 10, color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      s.rating.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueSortDropdown(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.scaffoldBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _revenueSort,
          icon: Icon(
            Icons.arrow_drop_down,
            color: colors.textSecondary,
            size: 20,
          ),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: colors.cardBg,
          items:
              [
                    'Revenue High-Low',
                    'Revenue Low-High',
                    'Sort by Name',
                    'Sort by Volume',
                  ]
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _revenueSort = v);
          },
        ),
      ),
    );
  }

  Widget _buildLiveAnalyticsContainer({
    required String title,
    String? subtitle,
    required AppColorsExtension colors,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.info, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('On-demand', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: colors.info)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContainer({
    required String title,
    String? subtitle,
    required AppColorsExtension colors,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final n = (value is num) ? value : double.tryParse(value.toString()) ?? 0;
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)}K';
    return '₹$n';
  }

  String _compactNumber(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
