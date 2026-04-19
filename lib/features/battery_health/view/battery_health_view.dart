// lib/features/battery_health/view/battery_health_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/health_models.dart';
import '../data/repositories/health_repository.dart';
import '../widgets/health_detail_drawer.dart';
import '../widgets/record_reading_modal.dart';
import '../widgets/schedule_maintenance_modal.dart';
import '../../../core/widgets/admin_ui_components.dart';

// ==================================================================
// Providers
// ==================================================================
class BatteryFilterParams {
  final String? healthRange;
  final String? sortBy;
  final bool? needsAttention;
  final String? search;

  const BatteryFilterParams({
    this.healthRange,
    this.sortBy,
    this.needsAttention,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatteryFilterParams &&
          runtimeType == other.runtimeType &&
          healthRange == other.healthRange &&
          sortBy == other.sortBy &&
          needsAttention == other.needsAttention &&
          search == other.search;

  @override
  int get hashCode =>
      healthRange.hashCode ^
      sortBy.hashCode ^
      needsAttention.hashCode ^
      search.hashCode;
}
final healthOverviewProvider = FutureProvider.autoDispose<HealthOverview>((ref) {
  return ref.watch(healthRepositoryProvider).getOverview();
});

final healthBatteriesProvider =
    FutureProvider.autoDispose.family<List<HealthBattery>, BatteryFilterParams>((
      ref,
      params,
    ) {
      return ref
          .watch(healthRepositoryProvider)
          .getBatteries(
            healthRange: params.healthRange,
            sortBy: params.sortBy ?? 'health_desc',
            needsAttention: params.needsAttention,
            search: params.search,
          );
    });

final healthAlertsProvider = FutureProvider.autoDispose<List<HealthAlert>>((ref) {
  return ref.watch(healthRepositoryProvider).getAlerts();
});

final healthAnalyticsProvider = FutureProvider.autoDispose<HealthAnalytics>((ref) {
  return ref.watch(healthRepositoryProvider).getAnalytics();
});

class BatteryHealthView extends ConsumerStatefulWidget {
  const BatteryHealthView({super.key});

  @override
  ConsumerState<BatteryHealthView> createState() => _BatteryHealthViewState();
}

class _BatteryHealthViewState extends ConsumerState<BatteryHealthView> {
  String? _selectedHealthRange;
  String _sortBy = 'health_desc';
  bool _needsAttention = false;
  String _searchQuery = '';
  String? _selectedBatteryId;
  bool _showDrawer = false;

  BatteryFilterParams get _filterParams => BatteryFilterParams(
    healthRange: _selectedHealthRange,
    sortBy: _sortBy,
    needsAttention: _needsAttention ? true : null,
    search: _searchQuery.isNotEmpty ? _searchQuery : null,
  );

  void _refresh() {
    ref.invalidate(healthOverviewProvider);
    ref.invalidate(healthAlertsProvider);
    ref.invalidate(healthAnalyticsProvider);
    // Batteries will refresh via _filterParams change
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(healthOverviewProvider);
    final alerts = ref.watch(healthAlertsProvider);
    final analytics = ref.watch(healthAnalyticsProvider);
    final batteries = ref.watch(healthBatteriesProvider(_filterParams));

    return Stack(
      children: [
        SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner
                alerts.when(
                  data: (alertList) => _buildAlertBanner(alertList),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Page Header
                _buildPageHeader(),
                const SizedBox(height: 24),

                // Summary Cards
                overview.when(
                  data: (data) => _buildSummaryCards(data),
                  loading: () => _buildLoadingCards(),
                  error: (e, _) =>
                      _buildErrorWidget('Failed to load overview: $e'),
                ),
                const SizedBox(height: 24),

                // Analytics Charts
                analytics.when(
                  data: (data) => _buildAnalyticsCharts(data),
                  loading: () => _buildLoadingCards(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Filter Pills + Sort
                _buildFilterBar(),
                const SizedBox(height: 16),

                // Battery Table
                batteries.when(
                  data: (list) => _buildBatteryTable(list),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                  error: (e, _) =>
                      _buildErrorWidget('Failed to load batteries: $e'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Detail Drawer
        if (_showDrawer && _selectedBatteryId != null)
          HealthDetailDrawer(
            batteryId: _selectedBatteryId!,
            onClose: () => setState(() {
              _showDrawer = false;
              _selectedBatteryId = null;
            }),
            onRefresh: _refresh,
          ),
      ],
    );
  }

  // ==================================================================
  // ALERT BANNER
  // ==================================================================
  Widget _buildAlertBanner(List<HealthAlert> alerts) {
    final critical = alerts.where((a) => a.severity == 'critical').toList();
    final warnings = alerts.where((a) => a.severity == 'warning').toList();

    if (critical.isEmpty && warnings.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        if (critical.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444).withValues(alpha: 0.15),
                  const Color(0xFFEF4444).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITICAL: ${critical.length} ${critical.length == 1 ? 'battery' : 'batteries'} require immediate attention',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        critical
                            .map((a) => a.batterySerial ?? 'Unknown')
                            .take(3)
                            .join(', '),
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedHealthRange = 'critical';
                  }),
                  child: Text(
                    'View Batteries →',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

        if (warnings.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  const Color(0xFFF59E0B).withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠ WARNING: ${warnings.length} ${warnings.length == 1 ? 'battery' : 'batteries'} showing rapid degradation',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _needsAttention = true;
                  }),
                  child: Text(
                    'Review Now →',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: -0.2),
      ],
    );
  }

  // ==================================================================
  // PAGE HEADER
  // ==================================================================
  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Battery Health Monitor',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Track degradation, schedule maintenance, and predict end-of-life',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
        // Action Buttons
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildOutlinedButton(
                Icons.bar_chart_rounded,
                'Health Report',
                const Color(0xFF8B5CF6),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Health Report generated and saved to PDF.',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildOutlinedButton(
                Icons.build_rounded,
                'Schedule Maintenance',
                const Color(0xFFF59E0B),
                () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        ScheduleMaintenanceModal(onSuccess: _refresh),
                  );
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RecordReadingModal(onSuccess: _refresh),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Record Reading',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================================================================
  // SUMMARY CARDS
  // ==================================================================
  Widget _buildSummaryCards(HealthOverview data) {
    return Row(
      children:
          [
                _buildSummaryCard(
                  'Fleet Avg Health',
                  '${data.fleetAvgHealth.toStringAsFixed(1)}%',
                  'Fleet average score',
                  const Color(0xFF3B82F6),
                  Icons.favorite_rounded,
                  null,
                  showArc: true,
                  arcValue: data.fleetAvgHealth,
                ),
                _buildSummaryCard(
                  'Good Health',
                  '${data.goodCount}',
                  '> 80% • ${data.totalBatteries > 0 ? (data.goodCount / data.totalBatteries * 100).toStringAsFixed(0) : 0}% of fleet',
                  const Color(0xFF10B981),
                  Icons.check_circle_rounded,
                  'good',
                ),
                _buildSummaryCard(
                  'Fair Health',
                  '${data.fairCount}',
                  '50-80% • Monitor closely',
                  const Color(0xFFF59E0B),
                  Icons.remove_circle_rounded,
                  'fair',
                ),
                _buildSummaryCard(
                  'Poor / Critical',
                  '${data.poorCount + data.criticalCount}',
                  '< 50% • Attention required',
                  const Color(0xFFEF4444),
                  Icons.cancel_rounded,
                  'poor',
                  pulse: data.poorCount + data.criticalCount > 0,
                ),
                _buildSummaryCard(
                  'Scheduled Service',
                  '${data.scheduledMaintenanceCount}',
                  'Next 7 days',
                  const Color(0xFF8B5CF6),
                  Icons.calendar_month_rounded,
                  null,
                ),
                _buildSummaryCard(
                  'Degradation Rate',
                  '${data.avgDegradationRate}%/mo',
                  'Avg monthly drop',
                  const Color(0xFF06B6D4),
                  Icons.trending_down_rounded,
                  null,
                ),
              ]
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: card,
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
    String? filterValue, {
    bool pulse = false,
    bool showArc = false,
    double arcValue = 0,
  }) {
    return MouseRegion(
      cursor: filterValue != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: filterValue != null
            ? () => setState(() {
                _selectedHealthRange = _selectedHealthRange == filterValue
                    ? null
                    : filterValue;
              })
            : null,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_selectedHealthRange == filterValue && filterValue != null)
                ? color.withValues(alpha: 0.12)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  (_selectedHealthRange == filterValue && filterValue != null)
                  ? color.withValues(alpha: 0.5)
                  : (pulse
                        ? color.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.04)),
              width: pulse ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const Spacer(),
                  if (showArc)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: arcValue / 100,
                        strokeWidth: 3,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ==================================================================
  // ANALYTICS CHARTS ROW
  // ==================================================================
  Widget _buildAnalyticsCharts(HealthAnalytics data) {
    return Row(
      children: [
        // Donut Chart
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Distribution',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: _buildDonutSections(
                              data.healthDistribution,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            'Good (>80%)',
                            data.healthDistribution['good'] ?? 0,
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            'Fair (50-80%)',
                            data.healthDistribution['fair'] ?? 0,
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            'Poor (30-50%)',
                            data.healthDistribution['poor'] ?? 0,
                            const Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            'Critical (<30%)',
                            data.healthDistribution['critical'] ?? 0,
                            const Color(0xFF7F1D1D),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),
        ),
        const SizedBox(width: 16),
        // Line Chart — Fleet Health Trend
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Fleet Health Trend — 90 Days',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _buildChartRangeChip('30D'),
                    _buildChartRangeChip('60D'),
                    _buildChartRangeChip('90D', selected: true),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220, // Give the chart a specific height so it renders
                  child: _buildFleetTrendChart(data.fleetTrend),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildDonutSections(Map<String, int> dist) {
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];

    final items = [
      {
        'key': 'good',
        'color': const Color(0xFF10B981),
        'value': dist['good'] ?? 0,
      },
      {
        'key': 'fair',
        'color': const Color(0xFFF59E0B),
        'value': dist['fair'] ?? 0,
      },
      {
        'key': 'poor',
        'color': const Color(0xFFEF4444),
        'value': dist['poor'] ?? 0,
      },
      {
        'key': 'critical',
        'color': const Color(0xFF7F1D1D),
        'value': dist['critical'] ?? 0,
      },
    ];

    return items.where((i) => (i['value'] as int) > 0).map((i) {
      final val = i['value'] as int;
      return PieChartSectionData(
        value: val.toDouble(),
        title: '$val',
        color: i['color'] as Color,
        radius: 35,
        titleStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFleetTrendChart(List<FleetHealthTrendPoint> trend) {
    if (trend.isEmpty) {
      return const Center(
        child: Text('No trend data', style: TextStyle(color: Colors.white38)),
      );
    }

    final validTrend = trend.where((t) => t.avgHealth > 0).toList();
    if (validTrend.length < 2) {
      return const Center(
        child: Text(
          'Not enough trend data',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final spots = validTrend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avgHealth))
        .toList();
    final minY =
        (validTrend.map((t) => t.avgHealth).reduce((a, b) => a < b ? a : b) - 5)
            .clamp(0, 100)
            .toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= validTrend.length) {
                  return const SizedBox.shrink();
                }
                final d = validTrend[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    d.substring(5),
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 9,
                    ),
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
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 80,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
            HorizontalLine(
              y: 50,
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)}%',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF3B82F6),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF3B82F6).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartRangeChip(String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? const Color(0xFF3B82F6) : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // FILTER BAR
  // ==================================================================
  Widget _buildFilterBar() {
    final filters = [
      {'label': 'All Batteries', 'value': null},
      {'label': 'Good (>80%)', 'value': 'good'},
      {'label': 'Fair (50-80%)', 'value': 'fair'},
      {'label': 'Poor (<50%)', 'value': 'poor'},
      {'label': 'Critical (<30%)', 'value': 'critical'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Filter Pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters.map((f) {
            final isSelected = _selectedHealthRange == f['value'];
            return FilterChip(
              selected: isSelected,
              label: Text(
                f['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              backgroundColor: const Color(0xFF1E293B),
              checkmarkColor: const Color(0xFF3B82F6),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (_) => setState(() {
                _selectedHealthRange = isSelected ? null : f['value'];
              }),
            );
          }).toList(),
        ),

        // Search
        SizedBox(
          width: 200,
          height: 38,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search serial...',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white24,
                size: 18,
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),

        // Sort Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              dropdownColor: const Color(0xFF1E293B),
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              icon: const Icon(
                Icons.unfold_more,
                color: Colors.white38,
                size: 16,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'health_desc',
                  child: Text('Health High→Low'),
                ),
                DropdownMenuItem(
                  value: 'health_asc',
                  child: Text('Health Low→High'),
                ),
                DropdownMenuItem(
                  value: 'degradation_rate',
                  child: Text('Worst Degradation'),
                ),
                DropdownMenuItem(
                  value: 'last_service',
                  child: Text('Last Service Date'),
                ),
              ],
              onChanged: (v) => setState(() => _sortBy = v ?? 'health_desc'),
            ),
          ),
        ),

        // Needs Attention Toggle
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Needs Attention',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Switch(
              value: _needsAttention,
              onChanged: (v) => setState(() => _needsAttention = v),
              activeThumbColor: const Color(0xFFEF4444),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  // ==================================================================
  // BATTERY TABLE
  // ==================================================================
  Widget _buildBatteryTable(List<HealthBattery> batteries) {
    if (batteries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.battery_unknown_rounded,
                color: Colors.white12,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No batteries match this health filter',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _selectedHealthRange = null;
                  _needsAttention = false;
                  _searchQuery = '';
                }),
                child: Text(
                  'Clear Filters',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const ['Battery Serial', 'Health Score', 'Health Bar', 'Degradation', 'Last Reading', 'Voltage / Temp', 'Status', 'Maintenance', 'Actions'],
        rows: batteries.map((b) => _buildBatteryRow(b)).toList(),
        onRowTap: (i) => _openDrawer(batteries[i].id),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  TextStyle _headerStyle() => GoogleFonts.inter(
    color: Colors.white38,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  List<Widget> _buildBatteryRow(HealthBattery b) {
    final healthColor = b.healthPercentage > 80
        ? const Color(0xFF10B981)
        : b.healthPercentage > 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return [
      // Serial
      InkWell(
        onTap: () => _openDrawer(b.id),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_rounded, color: Colors.white24, size: 14),
                const SizedBox(width: 6),
                Text(b.serialNumber, style: GoogleFonts.jetBrainsMono(color: const Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            if (b.manufacturer != null)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(b.manufacturer!, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
              ),
          ],
        ),
      ),

      // Health Score with mini gauge
      Row(
        children: [
          SizedBox(
            width: 36, height: 36,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: b.healthPercentage / 100, strokeWidth: 3, backgroundColor: healthColor.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(healthColor)),
              Text('${b.healthPercentage.toInt()}', style: GoogleFonts.inter(color: healthColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 8),
          Text('${b.healthPercentage.toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: healthColor, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),

      // Health Bar
      SizedBox(
        width: 120,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(value: b.healthPercentage / 100, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(healthColor)),
        ),
      ),

      // Degradation Rate
      Row(
        children: [
          Icon(
            b.degradationRate > 0 ? Icons.trending_down_rounded : Icons.trending_flat_rounded,
            color: b.degradationRate > 3 ? const Color(0xFFEF4444) : b.degradationRate > 1 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            b.degradationRate > 0 ? '${b.degradationRate}%/mo' : 'Stable',
            style: GoogleFonts.inter(color: b.degradationRate > 3 ? const Color(0xFFEF4444) : b.degradationRate > 1 ? const Color(0xFFF59E0B) : const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),

      // Last Reading
      Text(
        b.lastReadingAt != null ? _formatRelativeDate(b.lastReadingAt!) : 'No readings',
        style: GoogleFonts.inter(color: b.lastReadingAt == null ? const Color(0xFFEF4444).withValues(alpha: 0.7) : Colors.white54, fontSize: 12),
      ),

      // Voltage / Temp
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bolt_rounded, color: Colors.amber.withValues(alpha: 0.6), size: 13),
            const SizedBox(width: 3),
            Text(b.voltage != null ? '${b.voltage!.toStringAsFixed(1)}V' : '--', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
          ]),
          const SizedBox(height: 2),
          Row(children: [
            Icon(Icons.thermostat_rounded, color: (b.temperature ?? 0) > 45 ? const Color(0xFFEF4444) : Colors.cyan.withValues(alpha: 0.6), size: 13),
            const SizedBox(width: 3),
            Text(b.temperature != null ? '${b.temperature!.toStringAsFixed(1)}°C' : '--', style: GoogleFonts.inter(color: (b.temperature ?? 0) > 45 ? const Color(0xFFEF4444) : Colors.white54, fontSize: 11)),
          ]),
        ],
      ),

      // Status
      StatusBadge(status: b.healthStatus),

      // Maintenance
      _buildMaintenanceCell(b),

      // Actions
      Row(
        children: [
          IconButton(onPressed: () => _openDrawer(b.id), icon: const Icon(Icons.info_outline_rounded, size: 18), color: Colors.white38, tooltip: 'View health profile'),
          IconButton(
            onPressed: () { showDialog(context: context, builder: (_) => ScheduleMaintenanceModal(batteryId: b.id, batterySerial: b.serialNumber, onSuccess: _refresh)); },
            icon: const Icon(Icons.calendar_month_rounded, size: 18), color: Colors.white38, tooltip: 'Schedule maintenance',
          ),
          IconButton(
            onPressed: () { showDialog(context: context, builder: (_) => RecordReadingModal(batteryId: b.id, batterySerial: b.serialNumber, onSuccess: _refresh)); },
            icon: const Icon(Icons.bar_chart_rounded, size: 18), color: Colors.white38, tooltip: 'Record reading',
          ),
        ],
      ),
    ];
  }

  Widget _buildMaintenanceCell(HealthBattery b) {
    if (b.daysSinceMaintenance == null) {
      return Row(
        children: [
          Icon(Icons.help_outline_rounded, color: Colors.white24, size: 14),
          const SizedBox(width: 4),
          Text(
            'No record',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
          ),
        ],
      );
    }

    final days = b.daysSinceMaintenance!;
    if (days > 30) {
      return Row(
        children: [
          Icon(Icons.error_rounded, color: const Color(0xFFEF4444), size: 14),
          const SizedBox(width: 4),
          Text(
            'Overdue',
            style: GoogleFonts.inter(
              color: const Color(0xFFEF4444),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (days > 25) {
      return Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: const Color(0xFFF59E0B),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Due soon',
            style: GoogleFonts.inter(
              color: const Color(0xFFF59E0B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Up to date',
            style: GoogleFonts.inter(
              color: const Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
  }

  void _openDrawer(String batteryId) {
    setState(() {
      _selectedBatteryId = batteryId;
      _showDrawer = true;
    });
  }

  String _formatRelativeDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 7) return '${diff.inDays}d ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return isoDate;
    }
  }

  // ==================================================================
  // LOADING / ERROR WIDGETS
  // ==================================================================
  Widget _buildLoadingCards() {
    return Row(
      children: List.generate(
        6,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _refresh,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
