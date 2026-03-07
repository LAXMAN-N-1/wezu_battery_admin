import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/providers/station_performance_provider.dart';
import '../../../../core/widgets/metric_card.dart';

class StationPerformanceView extends ConsumerWidget {
  final int stationId;
  final String stationName;

  const StationPerformanceView({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(performanceDateRangeProvider);
    final performanceAsync = ref.watch(stationPerformanceProvider(
      stationId: stationId,
      start: dateRange.start,
      end: dateRange.end,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '$stationName Performance',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          _DateRangePicker(
            start: dateRange.start,
            end: dateRange.end,
            onChanged: (start, end) {
              ref.read(performanceDateRangeProvider.notifier).updateRange(start, end);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: performanceAsync.when(
        data: (perf) => _buildContent(perf),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildContent(perf) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = width > 1200 ? 4 : (width > 600 ? 2 : 1);
              double childAspectRatio = width > 1200 ? 1.5 : (width > 600 ? 1.8 : 2.0);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  MetricCard(
                    title: 'Total Rentals',
                    value: perf.totalRentals.toString(),
                    trend: '+0%', // Placeholder trend
                    icon: Icons.electric_scooter,
                    color: Colors.blue,
                  ),
                  MetricCard(
                    title: 'Revenue',
                    value: '₹${perf.totalRevenue.toStringAsFixed(0)}',
                    trend: '+0%',
                    icon: Icons.currency_rupee,
                    color: Colors.green,
                  ),
                  MetricCard(
                    title: 'Avg. Duration',
                    value: '${perf.avgDurationMinutes.toStringAsFixed(1)}m',
                    trend: '+0%',
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    title: 'Utilization',
                    value: '${perf.utilizationRate.toStringAsFixed(1)}%',
                    trend: '+0%',
                    icon: Icons.battery_charging_full,
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Alerts Section (FR-ADMIN-STN-004)
          if (perf.utilizationRate < 30 || perf.totalRevenue < 500) ...[
            _SectionLabel(title: 'Performance Alerts', icon: Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      perf.utilizationRate < 30 
                          ? 'Low Utilization Alert: This station is performing below the targeted 30% utilization threshold.'
                          : 'Low Revenue Alert: Revenue generated is below the historical daily average for this zone.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Benchmarking Section (FR-ADMIN-STN-004)
          _SectionLabel(title: 'Station Benchmarking', icon: Icons.compare_arrows, color: Colors.blue),
          const SizedBox(height: 16),
          _BenchmarkingTable(perf: perf),
          const SizedBox(height: 32),

          // Charts
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _ChartCard(
                        title: 'Daily Rental & Revenue Trends',
                        chart: _TrendsChart(trends: perf.dailyTrends),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _ChartCard(
                        title: 'Peak Rental Hours',
                        chart: _PeakHoursChart(peakHours: perf.peakHours),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _ChartCard(
                      title: 'Daily Rental & Revenue Trends',
                      chart: _TrendsChart(trends: perf.dailyTrends),
                    ),
                    const SizedBox(height: 24),
                    _ChartCard(
                      title: 'Peak Rental Hours',
                      chart: _PeakHoursChart(peakHours: perf.peakHours),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final Function(DateTime, DateTime) onChanged;

  const _DateRangePicker({
    required this.start,
    required this.end,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM dd, yyyy');
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.05),
      label: Text(
        '${df.format(start)} - ${df.format(end)}',
        style: const TextStyle(color: Colors.white70),
      ),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(start: start, end: end),
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onChanged(picked.start, picked.end);
        }
      },
      avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;

  const _ChartCard({required this.title, required this.chart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 300, child: chart),
        ],
      ),
    );
  }
}

class _TrendsChart extends StatelessWidget {
  final List trends;
  const _TrendsChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) return const Center(child: Text('No trend data', style: TextStyle(color: Colors.white38)));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= trends.length) return const SizedBox.shrink();
                final date = DateTime.parse(trends[value.toInt()].date);
                return Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.rentals.toDouble())).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
          ),
          LineChartBarData(
            spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble() / 10)).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

class _PeakHoursChart extends StatelessWidget {
  final List peakHours;
  const _PeakHoursChart({required this.peakHours});

  @override
  Widget build(BuildContext context) {
    if (peakHours.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.white38)));

    return BarChart(
      BarChartData(
        barGroups: peakHours.map((p) => BarChartGroupData(
          x: p.hour,
          barRods: [BarChartRodData(toY: p.rentalCount.toDouble(), color: Colors.blueAccent, width: 12)],
        )).toList(),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

class _BenchmarkingTable extends StatelessWidget {
  final dynamic perf;
  const _BenchmarkingTable({required this.perf});

  @override
  Widget build(BuildContext context) {
    // Mocked averages for benchmarking
    const avgRentals = 450;
    const avgRevenue = 12000.0;
    const avgUtilization = 65.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _BenchmarkingRow(label: 'Rentals', current: perf.totalRentals.toDouble(), average: avgRentals.toDouble(), unit: ''),
          const Divider(color: Colors.white10),
          _BenchmarkingRow(label: 'Revenue', current: perf.totalRevenue, average: avgRevenue, unit: '₹'),
          const Divider(color: Colors.white10),
          _BenchmarkingRow(label: 'Utilization', current: perf.utilizationRate, average: avgUtilization, unit: '%'),
        ],
      ),
    );
  }
}

class _BenchmarkingRow extends StatelessWidget {
  final String label;
  final double current;
  final double average;
  final String unit;

  const _BenchmarkingRow({required this.label, required this.current, required this.average, required this.unit});

  @override
  Widget build(BuildContext context) {
    final diff = ((current - average) / average) * 100;
    final isPos = diff >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$unit${current.toStringAsFixed(1)}',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPos ? Icons.trending_up : Icons.trending_down, color: isPos ? Colors.green : Colors.red, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${diff.abs().toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(color: isPos ? Colors.green : Colors.red, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
