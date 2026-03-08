import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_themes.dart';
import '../providers/dashboard_providers.dart';
import '../data/dashboard_models.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Platform Analytics',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _handleExport(context, ref),
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
            _buildRevenueSection(context, ref, colors),
            const SizedBox(height: 24),
            _buildUserBehaviorSection(context, ref, colors),
            const SizedBox(height: 24),
            _buildFunnelAndGrowthSection(context, ref, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBehaviorSection(
    BuildContext context,
    WidgetRef ref,
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
            data: (data) => Row(
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

  Widget _buildFunnelAndGrowthSection(
    BuildContext context,
    WidgetRef ref,
    AppColorsExtension colors,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVertical = screenWidth < 1200;

    if (isVertical) {
      return Column(
        children: [
          _buildGrowthChart(ref, colors),
          const SizedBox(height: 24),
          _buildDetailedFunnel(ref, colors),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildGrowthChart(ref, colors)),
        const SizedBox(width: 24),
        Expanded(child: _buildDetailedFunnel(ref, colors)),
      ],
    );
  }

  Widget _buildGrowthChart(WidgetRef ref, AppColorsExtension colors) {
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
              data: (data) => LineChart(
                key: const ValueKey('analytics_user_growth_chart'),
                LineChartData(
                  gridData: const FlGridData(show: false),
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
                          if (idx < 0 || idx >= data.points.length)
                            return const SizedBox();
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
                        return FlSpot(
                          e.key.toDouble(),
                          e.value.totalUsers.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: colors.accent,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.accent.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedFunnel(WidgetRef ref, AppColorsExtension colors) {
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
                            color: colors.textSecondary,
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

  Widget _buildRevenueSection(
    BuildContext context,
    WidgetRef ref,
    AppColorsExtension colors,
  ) {
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
    final displayData = data.stations.take(8).toList();
    final maxY = displayData.isEmpty
        ? 100.0
        : (displayData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) *
              1.2);

    return BarChart(
      key: const ValueKey('analytics_station_revenue_chart'),
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
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
                  final label = displayData[index].stationName;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 5 ? '${label.substring(0, 5)}..' : label,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 10,
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                _compactNumber(value),
                style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
          horizontalInterval: maxY / 4,
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
                color: e.key % 3 == 0
                    ? colors.success
                    : e.key % 3 == 1
                    ? Colors.orange
                    : colors.secondary,
                width: 22,
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
    final displayData = data.types;
    final maxY = displayData.isEmpty
        ? 100.0
        : (displayData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) *
              1.2);

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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < displayData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayData[index].type.split(' ').first,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: displayData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.revenue,
                color: e.key == 0
                    ? colors.success
                    : e.key == 1
                    ? Colors.orange
                    : colors.secondary,
                width: 40,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
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
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(analyticsRepositoryProvider);
    try {
      final response = await repo.exportReport();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export successful! Downloaded ${response.data.length} bytes.',
            ),
            backgroundColor: context.appColors.success,
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
