import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isPaused = ref.watch(refreshPausedProvider);
    final lastRefresh = ref.watch(lastRefreshTimeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, isPaused, lastRefresh),
          const SizedBox(height: 24),
          _buildDashboardContent(context, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(
    AppColorsExtension colors,
    bool isPaused,
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
                    color: (isPaused ? colors.warning : colors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPaused ? colors.warning : colors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPaused
                            ? 'Live Updates Paused'
                            : 'Live Updates Active',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPaused ? colors.warning : colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildRefreshControls(colors, isPaused),
      ],
    );
  }

  Widget _buildRefreshControls(AppColorsExtension colors, bool isPaused) {
    return Row(
      children: [
        IconButton(
          onPressed: () =>
              ref.read(refreshPausedProvider.notifier).state = !isPaused,
          icon: Icon(
            isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined,
            color: colors.textSecondary,
          ),
          tooltip: isPaused ? 'Resume Updates' : 'Pause Updates',
        ),
        IconButton(
          onPressed: () => ref.invalidate(dashboardOverviewProvider),
          icon: Icon(Icons.refresh_outlined, color: colors.textSecondary),
          tooltip: 'Refresh Now',
        ),
        const SizedBox(width: 8),
        _buildIntervalDropdown(colors),
      ],
    );
  }

  Widget _buildIntervalDropdown(AppColorsExtension colors) {
    final interval = ref.watch(refreshIntervalProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: interval,
          icon: Icon(
            Icons.timer_outlined,
            size: 16,
            color: colors.textTertiary,
          ),
          items: [5, 10, 30, 60]
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    '${e}s',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(refreshIntervalProvider.notifier).state = v;
            }
          },
        ),
      ),
    );
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
      ],
    );
  }

  Widget _buildKPIGrid(BuildContext context, AppColorsExtension colors) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400
        ? 4
        : screenWidth > 900
        ? 2
        : 1;

    return overviewAsync.when(
      data: (data) => GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          mainAxisExtent: 260,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            key: const ValueKey('metric_revenue'),
            title: 'Total Revenue',
            value: _formatCurrency(data.totalRevenue.value),
            subtitle: 'This month',
            trend: '+${data.totalRevenue.changePercent}%',
            trendLabel: 'vs last month',
            icon: Icons.currency_rupee,
            color: colors.success,
            sparkData: data.totalRevenue.sparkline,
          ),
          MetricCard(
            key: const ValueKey('metric_rentals'),
            title: 'Total Rentals',
            value: data.activeRentals.value.toString(),
            subtitle: 'Last 24 hours',
            trend: '+${data.activeRentals.changePercent}%',
            trendLabel: 'vs last month',
            icon: Icons.electric_scooter,
            color: colors.accent,
            sparkData: data.activeRentals.sparkline,
          ),
          MetricCard(
            key: const ValueKey('metric_users'),
            title: 'Active Users',
            value: data.totalUsers.value.toString(),
            subtitle: 'Currently online',
            trend: '+${data.totalUsers.changePercent}%',
            trendLabel: 'vs last month',
            icon: Icons.people_outline,
            color: colors.secondary,
            sparkData: data.totalUsers.sparkline,
          ),
          MetricCard(
            key: const ValueKey('metric_utilization'),
            title: 'Fleet Utilization',
            value: '${data.fleetUtilization.value}%',
            subtitle: 'Battery fleet',
            trend: '${data.fleetUtilization.changePercent}%',
            trendLabel: 'vs last month',
            icon: Icons.battery_charging_full,
            color: colors.warning,
            sparkData: data.fleetUtilization.sparkline,
          ),
        ],
      ),
      loading: () => GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
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
      children: [
        _legendItem('Revenue', colors.accent, colors),
        _legendItem('Rentals', Colors.orange, colors),
        _legendItem('Users', colors.secondary, colors),
        _legendItem('Battery Health', Colors.green, colors),
      ],
    );
  }

  Widget _legendItem(String label, Color color, AppColorsExtension colors) {
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
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        children: ['daily', 'weekly', 'monthly'].map((p) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.scaffoldBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {}, // TODO: Implement export
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
    if (data.points.isEmpty) return const Center(child: Text('No trend data'));

    return LineChart(
      key: const ValueKey('dashboard_main_trends_chart'),
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 3000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.border.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                  child: Text(
                    'Day $day',
                    style: GoogleFonts.inter(
                      color: colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3000,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactNumber(value),
                  style: GoogleFonts.inter(
                    color: colors.textTertiary,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _createTrendLine(
            data.points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble() + 1, e.value.revenue))
                .toList(),
            colors.accent,
            isPrimary: true,
          ),
          _createTrendLine(
            data.points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble() + 1, e.value.rentals))
                .toList(),
            colors.secondary,
          ),
          _createTrendLine(
            data.points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble() + 1, e.value.users))
                .toList(),
            const Color(0xFF9C27B0),
          ),
          _createTrendLine(
            data.points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble() + 1, e.value.batteryHealth))
                .toList(),
            colors.success,
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.cardBg,
            tooltipBorder: BorderSide(color: colors.border),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  _formatCurrency(spot.y),
                  GoogleFonts.outfit(
                    color: spot.bar.color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
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
          Text(
            'Station Health',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: healthAsync.when(
              data: (data) => _buildDonutChart(data, colors),
              loading: () => healthAsync.hasValue
                  ? _buildDonutChart(healthAsync.value!, colors)
                  : const Center(child: CircularProgressIndicator()),
              error: (e, s) => healthAsync.hasValue
                  ? _buildDonutChart(healthAsync.value!, colors)
                  : Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    BatteryHealthDistribution data,
    AppColorsExtension colors,
  ) {
    final sections = data.buckets.map((b) {
      Color color;
      if (b.category.contains('Excellent')) {
        color = const Color(0xFF22C55E); // Green
      } else if (b.category.contains('Good')) {
        color = const Color(0xFFF59E0B); // Orange
      } else if (b.category.contains('Fair')) {
        color = const Color(0xFF3B82F6); // Blue
      } else {
        color = const Color(0xFFEF4444); // Red
      }

      return PieChartSectionData(
        value: b.percentage,
        title: '',
        color: color,
        radius: 25,
        showTitle: false,
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                key: const ValueKey('dashboard_battery_health_pie'),
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 70,
                  sections: sections,
                  startDegreeOffset: 270,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NumberFormat('#,###').format(data.totalBatteries),
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: data.buckets.map((b) {
            Color color;
            if (b.category.contains('Excellent')) {
              color = const Color(0xFF22C55E);
            } else if (b.category.contains('Good')) {
              color = const Color(0xFFF59E0B);
            } else if (b.category.contains('Fair')) {
              color = const Color(0xFF3B82F6);
            } else {
              color = const Color(0xFFEF4444);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    b.category,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${b.percentage.toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
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
        ? 0.0
        : (displayData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) *
              1.2);

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
    return _buildAnalyticsContainer(
      title: 'Recent Activity',
      colors: colors,
      child: activityAsync.when(
        data: (data) => _buildActivityList(data, colors),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  Widget _buildActivityList(
    RecentActivityData data,
    AppColorsExtension colors,
  ) {
    return ListView.builder(
      itemCount: data.activities.length,
      itemBuilder: (context, index) {
        final item = data.activities[index];
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, size: 20, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.time,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
            ],
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
                onPressed: () {},
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 32,
        horizontalMargin: 0,
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.textTertiary,
        ),
        columns: const [
          DataColumn(label: Text('Station ID')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Rentals')),
          DataColumn(label: Text('Revenue')),
          DataColumn(label: Text('Utilization')),
          DataColumn(label: Text('Rating')),
        ],
        rows: data.stations.asMap().entries.map((entry) {
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
                    Text(
                      s.id,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(s.location, style: const TextStyle(fontSize: 13))),
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
                  width: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: s.utilization / 100,
                            backgroundColor: colors.border.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              s.utilization > 80
                                  ? colors.success
                                  : s.utilization > 60
                                  ? Colors.orange
                                  : colors.warning,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${s.utilization.toInt()}%',
                        style: const TextStyle(fontSize: 11),
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
