import 'dart:async';
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
import '../../../core/services/csv/csv_service.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  static const Duration _autoRefreshInterval = Duration(seconds: 60);

  String _revenueSort = 'Revenue High-Low';
  int? _expandedActivity;
  final Set<int> _readActivities = {};
  String _topStationSort = 'rentals_desc';
  Timer? _refreshTimer;
  String _revenueView = 'Stations';

  @override
  void initState() {
    super.initState();
    // Auto-refresh at a safer interval to avoid backend request spikes.
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (mounted) {
        _manualRefreshAll();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lastRefresh = ref.watch(lastRefreshTimeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 150,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, lastRefresh),
            const SizedBox(height: 16),
            _buildDashboardContent(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors, DateTime? lastRefresh) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$greeting 👋',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),

            ElevatedButton.icon(
              onPressed: _manualRefreshAll,
              icon: Icon(Icons.refresh, size: 18, color: colors.textPrimary),
              label: Text(
                'Refresh',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'All systems operational',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textSecondary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (lastRefresh != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: colors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Updated ${DateFormat('h:mm a').format(lastRefresh)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colors.textSecondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _manualRefreshAll() {
    // One trigger update is enough because all dashboard providers watch it.
    ref.read(dashboardRefreshTriggerProvider.notifier).state++;
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
                Expanded(flex: 2, child: _buildConversionFunnelCard(colors)),
              ],
            ),
          )
        else
          Column(
            children: [
              _buildTopStationsCard(colors),
              const SizedBox(height: 24),
              SizedBox(height: 500, child: _buildConversionFunnelCard(colors)),
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
        ? 4
        : (screenWidth > 1000 ? 2 : (screenWidth > 600 ? 2 : 1));

    return overviewAsync.when(
      data: (data) => Column(
        children: [
          // Top Row: Large Cards
          GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: screenWidth > 1400
                ? 1.4
                : (screenWidth > 1000 ? 1.25 : 1.15),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricCard(
                key: const ValueKey('metric_revenue'),
                title: 'Total Revenue',
                value: _formatCurrency(data.totalRevenue.value),
                subtitle: 'This month',
                trend:
                    '${data.totalRevenue.changePercent < 0 ? '' : '+'}${data.totalRevenue.changePercent.toStringAsFixed(1)}%',
                trendLabel: 'Usage',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF10B981), // Emerald/Green
                changeValue: data.totalRevenue.changePercent,
                sparkData: data.totalRevenue.sparkline,
              ),
              MetricCard(
                key: const ValueKey('metric_rentals'),
                title: 'Active Rentals',
                value: data.activeRentals.value.toString(),
                subtitle: 'Last 24 hours',
                trend:
                    '${data.activeRentals.changePercent < 0 ? '' : '+'}${data.activeRentals.changePercent.toStringAsFixed(1)}%',
                trendLabel: 'Usage',
                icon: Icons.electric_bolt_rounded,
                color: const Color(0xFF3B82F6), // Blue
                changeValue: data.activeRentals.changePercent,
                sparkData: data.activeRentals.sparkline,
              ),
              MetricCard(
                key: const ValueKey('metric_users'),
                title: 'Total Users',
                value: data.totalUsers.value.toString(),
                subtitle: 'Currently online',
                trend:
                    '${data.totalUsers.changePercent < 0 ? '' : '+'}${data.totalUsers.changePercent.toStringAsFixed(1)}%',
                trendLabel: 'Usage',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF8B5CF6), // Purple
                changeValue: data.totalUsers.changePercent,
                sparkData: data.totalUsers.sparkline,
              ),
              MetricCard(
                key: const ValueKey('metric_utilization'),
                title: 'Fleet Utilization',
                value: '${data.fleetUtilization.value.toStringAsFixed(1)}%',
                subtitle: 'Battery fleet',
                trend:
                    '${data.fleetUtilization.changePercent < 0 ? '' : '+'}${data.fleetUtilization.changePercent.toStringAsFixed(1)}%',
                trendLabel: 'Usage',
                icon: Icons.battery_charging_full_rounded,
                color: const Color(0xFFF59E0B), // Amber/Orange
                changeValue: data.fleetUtilization.changePercent,
                sparkData: data.fleetUtilization.sparkline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bottom Row: Small Cards
          GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: screenWidth > 1400
                ? 3.5
                : (screenWidth > 1000 ? 3.0 : 2.6),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricCard(
                key: const ValueKey('metric_stations'),
                title: 'Active Stations',
                value: data.activeStations.value.toString(),
                subtitle: 'Across regions',
                trend: '',
                trendLabel: '',
                icon: Icons.ev_station_rounded,
                color: const Color(0xFF06B6D4), // Cyan
              ),
              MetricCard(
                key: const ValueKey('metric_dealers'),
                title: 'Active Dealers',
                value: data.activeDealers.value.toString(),
                subtitle: 'Network partners',
                trend: '',
                trendLabel: '',
                icon: Icons.handshake_rounded,
                color: const Color(0xFFEC4899), // Pink
              ),
              MetricCard(
                key: const ValueKey('metric_health'),
                title: 'Avg. Battery Health',
                value: '${data.avgBatteryHealth.value.toStringAsFixed(0)}%',
                subtitle: 'Overall health',
                trend: '',
                trendLabel: '',
                icon: Icons.security_rounded,
                color: const Color(0xFF22C55E), // Green
              ),
              MetricCard(
                key: const ValueKey('metric_tickets'),
                title: 'Open Tickets',
                value: data.openTickets.value.toString(),
                subtitle: 'Awaiting support',
                trend: '',
                trendLabel: '',
                icon: Icons.confirmation_number_rounded,
                color: const Color(0xFFF97316), // Orange
              ),
            ],
          ),
        ],
      ),
      loading: () => Column(
        children: [
          GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: screenWidth > 1400
                ? 1.4
                : (screenWidth > 1000 ? 1.25 : 1.15),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (index) => MetricCard(
                key: ValueKey('metric_loading_large_$index'),
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
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: screenWidth > 1400
                ? 3.5
                : (screenWidth > 1000 ? 3.0 : 2.6),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (index) => MetricCard(
                key: ValueKey('metric_loading_small_$index'),
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
        ],
      ),
      error: (e, s) => Center(
        child: Text(
          'Error loading metrics: $e',
          style: TextStyle(color: colors.danger),
        ),
      ),
    );
  }

  Widget _buildTrendsChart(AppColorsExtension colors) {
    final trendsAsync = ref.watch(trendDataProvider);
    final period = ref.watch(trendPeriodProvider);

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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend Analysis',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _trendSubtitle(period),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              _buildExportButton(trendsAsync.valueOrNull, colors),
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
    final availableMetrics = ref.watch(trendAvailableMetricsProvider);
    final activeMetrics = ref.watch(trendActiveMetricsProvider);

    return Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...availableMetrics.map((metric) {
          final isActive = activeMetrics.contains(metric.key);
          return InkWell(
            onLongPress: metric.canDelete
                ? () {
                    _deleteMetric(metric.key);
                  }
                : null,
            onSecondaryTap: metric.canDelete
                ? () {
                    _deleteMetric(metric.key);
                  }
                : null,
            onTap: () {
              ref.read(trendActiveMetricsProvider.notifier).update((state) {
                final newState = Set<String>.from(state);
                if (newState.contains(metric.key)) {
                  if (newState.length > 1) newState.remove(metric.key);
                } else {
                  newState.add(metric.key);
                }
                return newState;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: metric.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.cardBg, width: 2),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: metric.color.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      if (metric.canDelete)
                        Positioned(
                          child: Icon(
                            Icons.close,
                            size: 8,
                            color: colors.cardBg,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    metric.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? colors.textPrimary
                          : colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Add Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddSeriesDialog(colors),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.add, size: 14, color: colors.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle(AppColorsExtension colors) {
    final period = ref.watch(trendPeriodProvider);
    final normalizedPeriod = period.toLowerCase();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Daily', 'Weekly', 'Monthly'].map((p) {
          final isSelected =
              (p == 'Daily' &&
                  const {
                    'today',
                    '1d',
                    '24h',
                    'daily',
                  }.contains(normalizedPeriod)) ||
              (p == 'Weekly' &&
                  const {'7d', 'week', 'weekly'}.contains(normalizedPeriod)) ||
              (p == 'Monthly' &&
                  const {'30d', 'month', 'monthly'}.contains(normalizedPeriod));
          return GestureDetector(
            onTap: () => ref.read(trendPeriodProvider.notifier).state =
                p == 'Daily' ? 'today' : (p == 'Weekly' ? '7d' : '30d'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _trendSubtitle(String period) {
    final normalized = period.toLowerCase();
    if (const {'today', '1d', '24h', 'daily'}.contains(normalized)) {
      return 'Today performance';
    }
    if (const {'7d', 'week', 'weekly'}.contains(normalized)) {
      return 'Last 7 days performance';
    }
    if (const {'90d', 'quarter'}.contains(normalized)) {
      return 'Last 90 days performance';
    }
    return 'Last 30 days performance';
  }

  Widget _buildExportButton(TrendData? data, AppColorsExtension colors) {
    return PopupMenuButton<String>(
      color: colors.cardBg,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      position: PopupMenuPosition.under,
      tooltip: 'Export',
      onSelected: (value) {
        if (value == 'csv' && data != null) {
          _handleExportCsv(data);
        } else if (value == 'csv' && data == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wait for trend data to load before exporting'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ref.invalidate(trendDataProvider);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'csv',
          child: Text(
            'Export CSV',
            style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'png',
          child: Text(
            'Download PNG',
            style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Text(
            'Save as PDF',
            style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.cardBg.withValues(alpha: 0.5),
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
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendGraph(TrendData data, AppColorsExtension colors) {
    if (data.points.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final activeSet = ref.watch(trendActiveMetricsProvider);
    final availableMetrics = ref.watch(trendAvailableMetricsProvider);
    final activeMetrics = availableMetrics
        .where((m) => activeSet.contains(m.key))
        .toList();

    // Calculate dynamic maxY based on active series
    double maxVal = 0;
    for (final m in activeMetrics) {
      final localMax = data.points
          .map((p) => _getMetricValue(p, m.key))
          .fold<double>(0, (prev, v) => v > prev ? v : prev);
      if (localMax > maxVal) maxVal = localMax;
    }

    final double yAxisMax = math.max(14000.0, (maxVal / 1000).ceil() * 1000.0);
    const double horizontalInterval = 2000.0;

    return LineChart(
      key: const ValueKey('dashboard_main_trends_chart'),
      LineChartData(
        minY: 0,
        maxY: yAxisMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.border.withValues(alpha: 0.1),
            strokeWidth: 1,
            dashArray: [8, 4],
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
              interval: 7,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day == 1 ||
                    day == 5 ||
                    day == 15 ||
                    day == 25 ||
                    day == 30) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Day $day',
                      style: GoogleFonts.inter(
                        color: colors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: horizontalInterval,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return Text(
                    '0',
                    style: GoogleFonts.inter(
                      color: colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                if (value % 4000 == 0) {
                  return Text(
                    '${(value / 1000).toInt()}k',
                    style: GoogleFonts.inter(
                      color: colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: activeMetrics.map((m) {
          final spots = data.points.asMap().entries.map((e) {
            double val = _getMetricValue(e.value, m.key);
            return FlSpot(e.key.toDouble() + 1, val);
          }).toList();
          return _createTrendLine(spots, m.color, isStatic: m.isStatic);
        }).toList(),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: Colors.purpleAccent.withValues(alpha: 0.4),
                  strokeWidth: 2,
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: bar.color ?? Colors.white,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.cardBg.withValues(alpha: 0.95),
            tooltipBorder: BorderSide(
              color: colors.border.withValues(alpha: 0.2),
            ),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];
              final index = touchedSpots.first.x.toInt() - 1;
              if (index < 0 || index >= data.points.length) return [];
              final p = data.points[index];

              // Map touched spots to their metrics for labels
              final items = <LineTooltipItem?>[];

              // Find the primary/first active metric to host the multi-line tooltip
              if (touchedSpots.isNotEmpty) {
                // Create a consolidated multi-line list for the first spot
                final children = <TextSpan>[];
                for (int i = 0; i < activeMetrics.length; i++) {
                  final m = activeMetrics[i];
                  double val;
                  switch (m.key) {
                    case 'revenue':
                      val = p.revenue;
                      break;
                    case 'rentals':
                      val = p.rentals;
                      break;
                    case 'users':
                      val = p.users;
                      break;
                    case 'batteryHealth':
                      val = p.batteryHealth;
                      break;
                    default:
                      val = 0;
                  }

                  final displayVal = m.key == 'revenue'
                      ? '${(val / 1000).toInt()}k'
                      : val.toInt().toString();

                  children.add(
                    TextSpan(
                      text:
                          '${m.label}: $displayVal${i == activeMetrics.length - 1 ? '' : '\n'}',
                      style: GoogleFonts.inter(
                        color: m.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                items.add(
                  LineTooltipItem('', const TextStyle(), children: children),
                );

                // Suppress tooltips for other spots in the same group
                for (int i = 1; i < touchedSpots.length; i++) {
                  items.add(null);
                }
              }

              return items;
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
    bool isStatic = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: !isStatic, // Static lines like health distribution are straight
      curveSmoothness: 0.35,
      color: color,
      barWidth: isPrimary ? 3.5 : 2.5,
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
            'Overall network performance',
            style: GoogleFonts.inter(fontSize: 13, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: healthAsync.when(
              data: (data) {
                final poorBucket = data.buckets.firstWhere(
                  (b) => b.category.toLowerCase().contains('poor'),
                  orElse: () => const HealthBucket(
                    category: 'Poor',
                    count: 0,
                    percentage: 0,
                  ),
                );
                final needsMaintenance = poorBucket.percentage > 20;

                return Column(
                  children: [
                    Expanded(child: _buildDonutChartOnly(data, colors)),
                    if (needsMaintenance) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: colors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Action Required: ${poorBucket.percentage.toStringAsFixed(0)}% batteries below 80% health. Schedule maintenance soon.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartOnly(
    BatteryHealthDistribution data,
    AppColorsExtension colors,
  ) {
    // Map existing buckets to Good/Fair/Poor
    final mappedBuckets = data.buckets.map((b) {
      String category = 'Poor';
      Color color = colors.danger;

      if (b.category.toLowerCase().contains('excellent') ||
          b.category.toLowerCase().contains('good')) {
        category = 'Good';
        color = colors.success;
      } else if (b.category.toLowerCase().contains('fair')) {
        category = 'Fair';
        color = Colors.orange;
      }

      return (category: category, percentage: b.percentage, color: color);
    }).toList();

    // Group by category to avoid duplicates
    final grouped = <String, ({double percent, Color color})>{};
    for (var b in mappedBuckets) {
      if (grouped.containsKey(b.category)) {
        final existing = grouped[b.category]!;
        grouped[b.category] = (
          percent: existing.percent + b.percentage,
          color: b.color,
        );
      } else {
        grouped[b.category] = (percent: b.percentage, color: b.color);
      }
    }

    final sections = grouped.entries.map((e) {
      return PieChartSectionData(
        value: e.value.percent,
        title: '${e.value.percent.toStringAsFixed(0)}%',
        titleStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        color: e.value.color,
        radius: 35, // Thick premium segments
        showTitle: true,
        titlePositionPercentageOffset: 0.55,
        badgeWidget: _buildHealthBadge(e.key, colors),
        badgePositionPercentageOffset: 1.35, // Floating outside the ring
      );
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 75,
                  sections: sections,
                  startDegreeOffset: 270,
                  borderData: FlBorderData(show: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.totalBatteries.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'Stations',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHealthBadge(String category, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark slate badge from image
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        category,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildConversionFunnelCard(AppColorsExtension colors) {
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

    final totalCount = data.stages.first.count;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: data.stages.length,
            separatorBuilder: (context, index) {
              final stage = data.stages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_drop_down, color: colors.danger, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${stage.dropOffRate.toStringAsFixed(1)}% drop-off',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
            itemBuilder: (context, index) {
              final stage = data.stages[index];
              final percentage = totalCount > 0
                  ? (stage.count / totalCount)
                  : 0.0;

              Color stageColor;
              switch (index % 4) {
                case 0:
                  stageColor = colors.accent;
                  break;
                case 1:
                  stageColor = const Color(0xFFA855F7);
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

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.scaffoldBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stage.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          _compactNumber(stage.count.toDouble()),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.border.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  stageColor,
                                  stageColor.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: stageColor.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${stage.conversionRate.toStringAsFixed(1)}% Conv.',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}% of total',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: stageColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
              ? ((data.totalBatteries - data.totalAvailable) /
                    data.totalBatteries *
                    100)
              : 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _inventoryStat(
                    'Total',
                    data.totalBatteries.toString(),
                    colors.textPrimary,
                    colors,
                  ),
                  const SizedBox(width: 16),
                  _inventoryStat(
                    'Available',
                    data.totalAvailable.toString(),
                    colors.success,
                    colors,
                  ),
                  const SizedBox(width: 16),
                  _inventoryStat(
                    'Utilization',
                    '${utilization.toStringAsFixed(1)}%',
                    colors.accent,
                    colors,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: topItems.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: colors.border.withValues(alpha: 0.4)),
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    final inUse = item.rented;
                    final percentAvailable = item.total == 0
                        ? 0
                        : (item.available / item.total * 100);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.category,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item.total} units',
                              style: GoogleFonts.inter(
                                color: colors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: item.total == 0 ? 0 : inUse / item.total,
                            minHeight: 8,
                            backgroundColor: colors.border.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation(colors.accent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentAvailable.toStringAsFixed(1)}% available • $inUse in use',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
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

  Widget _inventoryStat(
    String label,
    String value,
    Color color,
    AppColorsExtension colors,
  ) {
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
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: colors.textTertiary),
        ),
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
    final maxY =
        [
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
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.points.length) {
                  return const SizedBox();
                }
                final label = data.points[idx].date.split('-').last;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    label,
                    style: TextStyle(color: colors.textTertiary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _createTrendLine(predictedSpots, colors.accent, isPrimary: true),
          if (actualSpots.isNotEmpty)
            _createTrendLine(actualSpots, colors.success),
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
    final title = 'Revenue Analytics';
    const action = SizedBox.shrink(); // Filter icon removed as requested

    if (_revenueView == 'Stations') {
      final stationAsync = ref.watch(revenueByStationProvider);
      return _buildAnalyticsContainer(
        title: title,
        subtitle: 'Distribution by station',
        colors: colors,
        action: action,
        child: stationAsync.when(
          data: (data) => _buildRevenueChartByStation(data, colors),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),
      );
    } else {
      final batteryAsync = ref.watch(revenueByBatteryTypeProvider);
      return _buildAnalyticsContainer(
        title: title,
        subtitle: 'Distribution by battery type',
        colors: colors,
        action: action,
        child: batteryAsync.when(
          data: (data) => _buildRevenueChartByBattery(data, colors),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),
      );
    }
  }

  Widget _buildRevenueChartByStation(
    StationRevenueData data,
    AppColorsExtension colors,
  ) {
    List<StationRevenue> sorted = List.from(data.stations);
    if (_revenueSort == 'Revenue High-Low') {
      sorted.sort((a, b) => b.revenue.compareTo(a.revenue));
    } else if (_revenueSort == 'Revenue Low-High') {
      sorted.sort((a, b) => a.revenue.compareTo(b.revenue));
    } else {
      sorted.sort((a, b) => a.stationName.compareTo(b.stationName));
    }

    final displayData = sorted.take(6).toList();
    final rawMaxY = displayData.isEmpty
        ? 10000.0
        : displayData.map((e) => e.revenue).reduce(math.max) * 1.15;

    final interval = _calculateInterval(rawMaxY);
    final finalMaxY = ((rawMaxY / interval).ceil() * interval).toDouble();

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
            BarChartData(
              maxY: finalMaxY,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E293B),
                  tooltipBorderRadius: BorderRadius.circular(12),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final station = displayData[groupIndex];
                    return BarTooltipItem(
                      '${station.stationName}\n',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '13\n', // Mock additional metric like in image
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '₹${station.revenue.toInt()}',
                          style: GoogleFonts.outfit(
                            color: _getChartColor(groupIndex, colors),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: displayData.asMap().entries.map((e) {
                final barColor = _getChartColor(e.key, colors);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.revenue,
                      color: barColor,
                      width: 32,
                      borderRadius: BorderRadius.circular(8),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: finalMaxY,
                        color: colors.border.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: _getBarTitles(
                displayData
                    .map(
                      (e) => e.stationName
                          .substring(0, math.min(3, e.stationName.length))
                          .toUpperCase(),
                    )
                    .toList(),
                colors,
                interval,
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colors.border.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              alignment: BarChartAlignment.spaceAround,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChartByBattery(
    BatteryTypeRevenueData data,
    AppColorsExtension colors,
  ) {
    final displayData = data.types;
    final rawMaxY = displayData.isEmpty
        ? 10000.0
        : displayData.map((e) => e.revenue).reduce(math.max) * 1.15;

    final interval = _calculateInterval(rawMaxY);
    final finalMaxY = ((rawMaxY / interval).ceil() * interval).toDouble();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [_buildRevenueToggle(colors)],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: finalMaxY,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E293B),
                  tooltipBorderRadius: BorderRadius.circular(12),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final type = displayData[groupIndex];
                    return BarTooltipItem(
                      '${type.type}\n',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '13\n', // Mock additional metric
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '₹${type.revenue.toInt()}',
                          style: GoogleFonts.outfit(
                            color: _getChartColor(groupIndex, colors),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: displayData.asMap().entries.map((e) {
                final barColor = _getChartColor(e.key, colors);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.revenue,
                      color: barColor,
                      width: 40,
                      borderRadius: BorderRadius.circular(10),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: finalMaxY,
                        color: colors.border.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: _getBarTitles(
                displayData
                    .map(
                      (e) => e.type
                          .substring(0, math.min(3, e.type.length))
                          .toUpperCase(),
                    )
                    .toList(),
                colors,
                interval,
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colors.border.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              alignment: BarChartAlignment.spaceAround,
            ),
          ),
        ),
      ],
    );
  }

  Color _getChartColor(int index, AppColorsExtension colors) {
    final List<Color> palette = [
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Emerald
      const Color(0xFFFACC15), // Yellow
      const Color(0xFFF97316), // Orange
      const Color(0xFF3B82F6), // Blue
    ];
    return palette[index % palette.length];
  }

  FlTitlesData _getBarTitles(
    List<String> labels,
    AppColorsExtension colors,
    double interval,
  ) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();

            final label = labels[i];
            return SideTitleWidget(
              meta: meta,
              space: 12,
              angle: 0, // No rotation as requested
              child: SizedBox(
                width: 60,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50, // Increased to prevent clipping
          interval: interval,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value > meta.max * 0.99) return const SizedBox();
            return SideTitleWidget(
              meta: meta,
              space: 8,
              child: Text(
                _compactNumber(value),
                style: GoogleFonts.inter(
                  color: colors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600, // Unified with Trend style
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 0) return 1.0;
    if (maxY <= 10) return 2.0;
    if (maxY <= 50) return 10.0;
    if (maxY <= 100) return 20.0;
    if (maxY <= 1000) return 200.0;
    if (maxY <= 10000) return 2000.0;

    // For revenue values in Lakhs (0.2L, 0.5L, 1.0L steps)
    if (maxY <= 200000) return 20000.0; // 0.2L intervals for 0-2L range
    if (maxY <= 500000) return 50000.0; // 0.5L intervals for 0-5L range
    if (maxY <= 1000000) return 100000.0; // 1L intervals for 0-10L range

    double magnitude = math
        .pow(10, (math.log(maxY) / math.ln10).floor())
        .toDouble();
    double interval = magnitude / 5;
    if (interval < 1) return 1.0;
    return interval;
  }

  Widget _buildRevenueToggle(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Stations',
            isActive: _revenueView == 'Stations',
            onTap: () => setState(() => _revenueView = 'Stations'),
            colors: colors,
          ),
          _buildToggleButton(
            label: 'Batteries',
            isActive: _revenueView == 'Batteries',
            onTap: () => setState(() => _revenueView = 'Batteries'),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? colors.textPrimary : colors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(AppColorsExtension colors) {
    final activityAsync = ref.watch(recentActivityProvider);
    return _buildLiveAnalyticsContainer(
      title: 'Recent Activity',
      colors: colors,
      child: activityAsync.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: _buildActivityList(data, colors))],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
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
                      color: isRead
                          ? colors.border
                          : iconColor.withValues(alpha: 0.4),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (item.severity == 'critical'
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
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
                onPressed: () =>
                    GoRouter.of(context).go('/stations/performance'),
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
      child: SingleChildScrollView(
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
                  _topStationSort =
                      _topStationSort.startsWith('rentals') &&
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
                  _topStationSort =
                      _topStationSort.startsWith('revenue') &&
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
                  _topStationSort =
                      _topStationSort.startsWith('utilization') &&
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
                                          titlesData: const FlTitlesData(
                                            show: false,
                                          ),
                                          gridData: const FlGridData(
                                            show: false,
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: s.sparkline
                                                  .asMap()
                                                  .entries
                                                  .map(
                                                    (e) => FlSpot(
                                                      e.key.toDouble(),
                                                      e.value,
                                                    ),
                                                  )
                                                  .toList(),
                                              isCurved: true,
                                              color: colors.accent,
                                              barWidth: 3,
                                              dotData: const FlDotData(
                                                show: false,
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: colors.accent.withValues(
                                                  alpha: 0.1,
                                                ),
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
                DataCell(
                  Text(
                    s.location.isNotEmpty ? s.location : s.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
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
                                        : 100 -
                                              s.utilization -
                                              s.offlinePercent;
                                    return val <= 0
                                        ? 1
                                        : val.clamp(1, 100).toInt();
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
                                      color: colors.textTertiary.withValues(
                                        alpha: 0.4,
                                      ),
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

                            Text(
                              '${s.availablePercent.toInt()}% avail',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textTertiary,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.info,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'On-demand',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.info,
                              ),
                            ),
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
          Expanded(child: IgnorePointer(ignoring: false, child: child)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContainer({
    required String title,
    String? subtitle,
    required AppColorsExtension colors,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
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
              ),
              if (action != null) action,
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
    if (n >= 100000) {
      final l = n / 100000;
      return '₹${l % 1 == 0 ? l.toInt() : l.toStringAsFixed(1)}L';
    }
    if (n >= 1000) {
      final k = n / 1000;
      return '₹${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '₹${n.toInt()}';
  }

  String _compactNumber(double n) {
    if (n >= 100000) {
      final l = n / 100000;
      return '${l % 1 == 0 ? l.toInt() : l.toStringAsFixed(1)}L';
    }
    if (n >= 10000) {
      // 20k -> 0.2L
      final l = n / 100000;
      return '${l % 1 == 0 ? l.toInt() : l.toStringAsFixed(1)}L';
    }
    if (n >= 1000) {
      final k = n / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return n.toInt().toString();
  }

  void _deleteMetric(String key) {
    ref
        .read(trendAvailableMetricsProvider.notifier)
        .update((state) => state.where((m) => m.key != key).toList());
    ref.read(trendActiveMetricsProvider.notifier).update((state) {
      final newState = Set<String>.from(state);
      newState.remove(key);
      return newState;
    });
  }

  void _handleExportCsv(TrendData data) async {
    final activeSet = ref.read(trendActiveMetricsProvider);
    final availableMetrics = ref.read(trendAvailableMetricsProvider);
    final activeMetrics = availableMetrics
        .where((m) => activeSet.contains(m.key))
        .toList();

    List<List<dynamic>> rows = [
      ['Date', ...activeMetrics.map((m) => m.label)],
    ];

    for (var p in data.points) {
      List<dynamic> row = [p.date];
      for (var m in activeMetrics) {
        row.add(_getMetricValue(p, m.key));
      }
      rows.add(row);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'trend_analysis_$timestamp';

    try {
      await CsvService.downloadCsv(rows, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Trend data exported successfully',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getMetricValue(TrendPoint p, String key) {
    switch (key) {
      case 'revenue':
        return p.revenue;
      case 'rentals':
        return p.rentals;
      case 'users':
        return p.users;
      case 'batteryHealth':
        return p.batteryHealth;
      default:
        // Deterministic mock data for custom series
        // Use hash of key + date to get a stable value between 1000 and 7000
        final combined = '$key${p.date}';
        final hash = combined
            .split('')
            .fold<int>(0, (prev, char) => prev + char.codeUnitAt(0));
        return 1000.0 + (hash % 6000).toDouble();
    }
  }

  void _showAddSeriesDialog(AppColorsExtension colors) {
    String seriesName = '';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E283F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Data Series',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (val) => seriesName = val,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Series Name (e.g., Station Load)',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (seriesName.trim().isEmpty) return;

                      final newKey = seriesName.toLowerCase().replaceAll(
                        ' ',
                        '_',
                      );
                      final randomColor =
                          Colors.primaries[seriesName.length %
                              Colors.primaries.length];

                      ref.read(trendAvailableMetricsProvider.notifier).update((
                        state,
                      ) {
                        return [
                          ...state,
                          TrendMetric(
                            label: seriesName,
                            key: newKey,
                            color: randomColor,
                            canDelete: true,
                          ),
                        ];
                      });

                      ref.read(trendActiveMetricsProvider.notifier).update((
                        state,
                      ) {
                        return {...state, newKey};
                      });

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Series',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
