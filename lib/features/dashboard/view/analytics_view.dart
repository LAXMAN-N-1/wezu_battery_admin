import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_themes.dart';
import '../providers/dashboard_providers.dart';
import '../data/dashboard_models.dart';
import '../../../core/services/csv/csv_service.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView> {
  final String _stationMetric = 'revenue'; // revenue | rentals | utilization

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Platform Analytics',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                
                _buildPeriodSelector(colors),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _manualRefreshAll,
                  tooltip: 'Refresh data',
                  icon: Icon(
                    Icons.refresh_outlined,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _handleExport(context),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRevenueSection(context, colors),
            const SizedBox(height: 24),
            _buildUserBehaviorSection(context, colors),
            const SizedBox(height: 24),
            _buildFunnelAndGrowthSection(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppColorsExtension colors) {
    final period = ref.watch(analyticsPeriodProvider);
    const options = ['today', '7d', '30d', '90d'];
    return Wrap(
      spacing: 8,
      children: options.map((p) {
        final isSelected = p == period;
        return ChoiceChip(
          label: Text(
            p.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
          selected: isSelected,
          onSelected: (_) =>
              ref.read(analyticsPeriodProvider.notifier).state = p,
          selectedColor: colors.accent,
          backgroundColor: colors.scaffoldBg.withValues(alpha: 0.4),
          side: BorderSide(color: colors.border),
        );
      }).toList(),
    );
  }

  Widget _buildUserBehaviorSection(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    final behaviorAsync = ref.watch(userBehaviorProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Behavior Analysis',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          behaviorAsync.when(
            data: (data) => Column(
              children: [
                Row(
                  children: [
                    _buildBehaviorStat(
                      'Avg. Session',
                      '${data.avgSessionDuration.toStringAsFixed(1)}m',
                      colors,
                    ),
                    _buildBehaviorStat(
                      'Rentals/User',
                      data.avgRentalsPerUser.toStringAsFixed(1),
                      colors,
                    ),
                    _buildBehaviorStat(
                      'Peak Traffic',
                      data.peakHours.keys.isNotEmpty
                          ? data.peakHours.keys.first
                          : 'N/A',
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(child: _buildSessionHistogram(data, colors)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCohortBreakdown(data, colors)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 220, child: _buildHeatmap(data, colors)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorStat(
    String label,
    String value,
    AppColorsExtension colors,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.accent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistogram(UserBehavior data, AppColorsExtension colors) {
    final buckets = data.sessionHistogram.isNotEmpty
        ? data.sessionHistogram
        : [
            SessionBucket(range: '0-5m', count: 100),
            SessionBucket(range: '5-10m', count: 220),
            SessionBucket(range: '10-15m', count: 180),
            SessionBucket(range: '15-20m', count: 120),
            SessionBucket(range: '20m+', count: 80),
          ];
    final maxY = buckets
        .map((b) => b.count)
        .fold<int>(0, (prev, element) => element > prev ? element : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Duration Histogram',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxY * 1.2).toDouble(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < buckets.length) {
                        return Text(
                          buckets[idx].range,
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: buckets.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.count.toDouble(),
                      color: colors.accent,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
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

  Widget _buildCohortBreakdown(UserBehavior data, AppColorsExtension colors) {
    final cohorts = data.cohortBreakdown.isNotEmpty
        ? data.cohortBreakdown
        : {'New Users': 60.0, 'Returning Users': 40.0};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cohort Breakdown',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...cohorts.entries.map((e) {
          final percent = e.value;
          final barColor = e.key.toLowerCase().contains('return')
              ? colors.secondary
              : colors.success;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: TextStyle(color: colors.textSecondary)),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 8,
                    backgroundColor: colors.border.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeatmap(UserBehavior data, AppColorsExtension colors) {
    List<List<int>> matrix = data.heatmap;
    if (matrix.isEmpty) {
      // build 7x24 from peak hours if provided, else default
      matrix = List.generate(7, (day) {
        return List.generate(
          24,
          (hour) => (hour >= 8 && hour <= 21)
              ? ((data.peakHours['$hour:00'] ?? 20) as num).toInt()
              : 5,
        );
      });
    }
    final maxVal = matrix
        .expand((row) => row)
        .fold<int>(0, (prev, e) => e > prev ? e : prev);
    Color cellColor(int value) {
      final intensity = maxVal == 0 ? 0.05 : (value / maxVal).clamp(0.05, 1.0);
      return colors.accent.withValues(alpha: intensity * 0.8);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peak Traffic Heatmap',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 24,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: matrix.length * 24,
            itemBuilder: (context, idx) {
              final day = idx ~/ 24;
              final hour = idx % 24;
              final value = matrix[day][hour];
              return Container(
                decoration: BoxDecoration(
                  color: cellColor(value),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelAndGrowthSection(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVertical = screenWidth < 1200;

    if (isVertical) {
      return Column(
        children: [
          _buildGrowthChart(colors),
          const SizedBox(height: 24),
          _buildDetailedFunnel(colors),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildGrowthChart(colors)),
        const SizedBox(width: 24),
        Expanded(child: _buildDetailedFunnel(colors)),
      ],
    );
  }

  Widget _buildGrowthChart(AppColorsExtension colors) {
    final growthAsync = ref.watch(userGrowthProvider);
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Growth Trends',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: growthAsync.when(
              data: (data) {
                if (data.points.length < 2) {
                  return const Center(
                    child: Text(
                      'Not enough growth data',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }
                return LineChart(
                  key: const ValueKey('analytics_user_growth_chart'),
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: data.points.isEmpty
                          ? 1
                          : (data.points
                                        .map((p) => p.totalUsers.toDouble())
                                        .reduce((a, b) => a > b ? a : b) /
                                    4)
                                .clamp(1, double.infinity),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colors.border.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value % 1 != 0) return const SizedBox();
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.points.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data.points[idx].period.split(' ').last,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data.points.asMap().entries.map((e) {
                          final returning = e.value.returningUsers.toDouble();
                          return FlSpot(e.key.toDouble(), returning);
                        }).toList(),
                        isCurved: true,
                        color: colors.secondary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors.secondary.withValues(alpha: 0.1),
                        ),
                      ),
                      LineChartBarData(
                        spots: data.points.asMap().entries.map((e) {
                          final total =
                              (e.value.returningUsers + e.value.newUsers)
                                  .toDouble();
                          return FlSpot(e.key.toDouble(), total);
                        }).toList(),
                        isCurved: true,
                        color: colors.accent,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedFunnel(AppColorsExtension colors) {
    final funnelAsync = ref.watch(conversionFunnelProvider);
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Funnel',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: funnelAsync.when(
              data: (data) => ListView.builder(
                itemCount: data.stages.length,
                itemBuilder: (context, index) {
                  final s = data.stages[index];
                  final widthFactor = s.conversionRate / 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${s.count}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: colors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: widthFactor,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.accent, colors.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Conversion: ${s.conversionRate}% | Drop-off: ${s.dropOffRate}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: s.dropOffRate > 30
                                ? colors.danger
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(BuildContext context, AppColorsExtension colors) {
    final stationRevenueAsync = ref.watch(revenueByStationProvider);
    final batteryRevenueAsync = ref.watch(revenueByBatteryTypeProvider);

    return Column(
      children: [
        if (MediaQuery.of(context).size.width > 1200)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildRevenueCard(
                  'Station Revenue Distribution',
                  null,
                  stationRevenueAsync,
                  colors,
                  isStation: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildRevenueCard(
                  'Battery Type Revenue',
                  'Distribution by model',
                  batteryRevenueAsync,
                  colors,
                  isStation: false,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildRevenueCard(
                'Station Revenue Distribution',
                null,
                stationRevenueAsync,
                colors,
                isStation: true,
              ),
              const SizedBox(height: 24),
              _buildRevenueCard(
                'Battery Type Revenue',
                'Distribution by model',
                batteryRevenueAsync,
                colors,
                isStation: false,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRevenueCard(
    String title,
    String? subtitle,
    AsyncValue<dynamic> asyncData,
    AppColorsExtension colors, {
    required bool isStation,
  }) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
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
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                    ),
                ],
              ),
              // Filter toggle removed as requested to keep it "perfect" for revenue focus
              // if (isStation) _buildStationMetricToggle(colors),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: asyncData.when(
              data: (data) => isStation
                  ? _buildStationBarChart(data as StationRevenueData, colors)
                  : _buildBatteryBarChart(
                      data as BatteryTypeRevenueData,
                      colors,
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationBarChart(
    StationRevenueData data,
    AppColorsExtension colors,
  ) {
    if (data.stations.isEmpty) {
      return const Center(
        child: Text('No station data', style: TextStyle(color: Colors.white38)),
      );
    }
    final displayData = data.stations.take(8).toList();

    double metricValue(StationRevenue r) {
      switch (_stationMetric) {
        case 'rentals':
          return r.rentalCount.toDouble();
        case 'utilization':
          return r.utilization > 0 ? r.utilization : r.percentage;
        default:
          return r.revenue;
      }
    }

    final sorted = List<StationRevenue>.from(displayData)
      ..sort((a, b) => metricValue(b).compareTo(metricValue(a)));
    final rawMaxY = displayData.isEmpty
        ? 10.0
        : math.max(metricValue(sorted.first) * 1.15, 1.0);
    // Round up to a nice multiple to avoid label collisions at the top
    final interval = _calculateInterval(rawMaxY);
    final maxY = ((rawMaxY / interval).ceil() * interval).toDouble();

    return BarChart(
      key: const ValueKey('analytics_station_revenue_chart'),
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY <= 0 ? 1 : maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.cardBg,
            tooltipBorder: BorderSide(color: colors.border),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${displayData[groupIndex].stationName}\n',
                GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text:
                        'Revenue: ${_formatCurrency(displayData[groupIndex].revenue)}\n',
                    style: TextStyle(color: colors.success),
                  ),
                  TextSpan(
                    text: 'Rentals: ${displayData[groupIndex].rentalCount}\n',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  if (displayData[groupIndex].avgSessionDuration > 0)
                    TextSpan(
                      text:
                          'Avg Session: ${displayData[groupIndex].avgSessionDuration.toStringAsFixed(1)}m',
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
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < displayData.length) {
                  final label = displayData[index].stationName;
                  return SideTitleWidget(
                    meta: meta,
                    space: 12,
                    angle: 0,
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
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value > maxY * 0.99) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    _compactNumber(value),
                    style: GoogleFonts.inter(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
        barGroups: displayData.asMap().entries.map((e) {
          final barColor = _getChartColor(e.key, colors);
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: metricValue(e.value),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [barColor, barColor.withValues(alpha: 0.7)],
                ),
                width: 32, // Thicker bars as requested
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBatteryBarChart(
    BatteryTypeRevenueData data,
    AppColorsExtension colors,
  ) {
    if (data.types.isEmpty && data.stationMix.isEmpty) {
      return const Center(
        child: Text(
          'No battery revenue data',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    // Prefer station-level stacked composition if available
    if (data.stationMix.isNotEmpty) {
      final stations = data.stationMix.take(5).toList();
      final rawMaxY =
          stations
              .map<double>(
                (s) => s.batteryMix.fold(0, (prev, b) => prev + b.revenue),
              )
              .fold<double>(
                0,
                (prev, element) => element > prev ? element : prev,
              ) *
          1.15;
      final interval = _calculateInterval(rawMaxY);
      final maxY = ((rawMaxY / interval).ceil() * interval).toDouble();

      return BarChart(
        key: const ValueKey('analytics_battery_revenue_chart'),
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY <= 0 ? 100 : maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.cardBg,
              tooltipBorder: BorderSide(color: colors.border),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final station = stations[groupIndex];
                final total = station.batteryMix.fold<double>(
                  0,
                  (prev, b) => prev + b.revenue,
                );
                return BarTooltipItem(
                  '${station.stationName}\n',
                  GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  children: station.batteryMix
                      .map(
                        (b) => TextSpan(
                          text:
                              '${b.type}: ${_formatCurrency(b.revenue)} (${(b.revenue / total * 100).toStringAsFixed(1)}%)\n',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < stations.length) {
                    final label = stations[index].stationName;
                    return SideTitleWidget(
                      meta: meta,
                      space: 12,
                      angle: 0,
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
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value > maxY * 0.99) return const SizedBox();
                  return Text(
                    _compactNumber(value),
                    style: GoogleFonts.inter(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.border.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: stations.asMap().entries.map((entry) {
            final station = entry.value;
            double running = 0;
            final stacks = station.batteryMix.map((mix) {
              final start = running;
              running += mix.revenue;
              return BarChartRodStackItem(
                start,
                running,
                mix.type.contains('LFP')
                    ? Colors.orange
                    : mix.type.toLowerCase().contains('nimh')
                    ? colors.secondary
                    : colors.success,
              );
            }).toList();

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: running,
                  width: 40, // Perfected width
                  rodStackItems: stacks,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                    bottom: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    // Fallback: aggregated types
    final displayData = data.types;
    final maxValue = displayData.isEmpty
        ? 10000.0
        : displayData.map((e) => e.revenue).reduce(math.max);
    // Align to 10k increments for Y axis
    final maxY = ((maxValue / 10000).ceil() * 10000).toDouble().clamp(
      30000.0,
      80000.0,
    );

    return BarChart(
      key: const ValueKey('analytics_battery_revenue_chart'),
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.cardBg,
            tooltipBorder: BorderSide(color: colors.border),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < displayData.length) {
                  final label = displayData[index].type;
                  return SideTitleWidget(
                    meta: meta,
                    space: 12,
                    angle: 0,
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
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 10000,
              getTitlesWidget: (value, meta) => Text(
                _compactNumber(value),
                style: GoogleFonts.inter(
                  color: colors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          horizontalInterval: 10000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.border.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: displayData.asMap().entries.map((e) {
          final barColor = _getChartColor(e.key, colors);
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.revenue,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [barColor, barColor.withValues(alpha: 0.7)],
                ),
                width: 32,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final n = (value is num) ? value : double.tryParse(value.toString()) ?? 0;
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)}K';
    return '₹${n.toInt()}';
  }

  String _compactNumber(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 10000) return '${(n / 100000).toStringAsFixed(1)}L'; // 20k -> 0.2L
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    // If integer, don't show decimal
    if (n == n.toInt().toDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
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

  Color _getChartColor(int index, AppColorsExtension colors) {
    final palette = [
      colors.accent,
      const Color(0xFFA855F7), // Purple
      const Color(0xFFF97316), // Orange
      colors.success,
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
    ];
    return palette[index % palette.length];
  }

  void _manualRefreshAll() {
    // One trigger update is enough because providers watch this state.
    ref.read(dashboardRefreshTriggerProvider.notifier).state++;
    ref.read(lastRefreshTimeProvider.notifier).state = DateTime.now();
  }

  Future<void> _handleExport(BuildContext context) async {
    final stationData = ref.read(revenueByStationProvider).valueOrNull;

    if (stationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export')),
      );
      return;
    }

    // Prepare CSV rows
    List<List<dynamic>> rows = [
      [
        'Station Name',
        'Revenue',
        'Rentals',
        'Utilization (%)',
        'Avg Session (m)',
        'Share (%)',
      ],
    ];

    for (var s in stationData.stations) {
      rows.add([
        s.stationName,
        s.revenue,
        s.rentalCount,
        '${s.utilization}%',
        s.avgSessionDuration,
        '${s.percentage}%',
      ]);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'analytics_report_$timestamp';

    try {
      await CsvService.downloadCsv(rows, fileName);
      if (context.mounted) {
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
                  'Analytics exported successfully',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: context.appColors.success,
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: context.appColors.danger,
          ),
        );
      }
    }
  }
}
