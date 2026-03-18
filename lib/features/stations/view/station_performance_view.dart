import 'package:flutter/material.dart';
<<<<<<< HEAD
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
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            alignment: Alignment.centerLeft,
            child: _DateRangePicker(
              start: dateRange.start,
              end: dateRange.end,
              onChanged: (start, end) {
                ref.read(performanceDateRangeProvider.notifier).updateRange(start, end);
              },
            ),
          ),
        ),
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
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
      backgroundColor: Colors.white.withValues(alpha: 0.05),
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
          initialEntryMode: DatePickerEntryMode.calendar,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E293B),
                  onSurface: Colors.white,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: child,
                  ),
                ),
              ),
            );
          },
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
=======
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationPerformanceView extends StatefulWidget {
  const StationPerformanceView({super.key});

  @override
  State<StationPerformanceView> createState() => _StationPerformanceViewState();
}

class _StationPerformanceViewState extends State<StationPerformanceView> {
  final StationRepository _repository = StationRepository();
  List<StationPerformance> _stations = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getAllPerformance();
      setState(() {
        _stations = data['stations'] as List<StationPerformance>;
        _summary = (data['summary'] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Station Performance',
            subtitle: 'Utilization rates, ratings, battery availability, and operational metrics across all stations.',
            actionButton: _buildRefreshButton(),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Summary Stats
          Row(
            children: [
              _buildStatCard('Total Stations', (_summary['total_stations'] ?? 0).toString(), Icons.ev_station_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Avg Utilization', '${(_summary['avg_utilization'] ?? 0.0).toStringAsFixed(1)}%', Icons.speed_outlined, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildStatCard('Avg Rating', (_summary['avg_rating'] ?? 0.0).toStringAsFixed(1), Icons.star_outline, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildStatCard('Total Batteries', (_summary['total_available_batteries'] ?? 0).toString(), Icons.battery_charging_full_outlined, const Color(0xFF8B5CF6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Performance Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : _stations.isEmpty
                    ? SizedBox(
                        height: 200,
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.analytics_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No performance data available', style: GoogleFonts.inter(color: Colors.white54)),
                        ])),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              const Icon(Icons.trending_up, color: Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 10),
                              Text('Performance Comparison', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Text('${_stations.length} stations', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                            ]),
                          ),
                          AdvancedTable(
                            columns: const ['Station', 'Status', 'Utilization', 'Slots', 'Batteries', 'Rating', 'Reviews', 'Power'],
                            rows: _stations.map((s) {
                              return [
                                // Station name
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(s.stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    if (s.city != null) Text(s.city!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                                // Status
                                StatusBadge(status: s.status),
                                // Utilization bar
                                _utilizationBar(s.utilizationPercentage),
                                // Slots
                                Text('${s.occupiedSlots}/${s.totalSlots}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                // Batteries
                                Text('${s.availableBatteries}', style: TextStyle(
                                  color: s.availableBatteries > 0 ? const Color(0xFF22C55E) : Colors.white38,
                                  fontWeight: FontWeight.bold, fontSize: 13,
                                )),
                                // Rating
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.star, size: 14, color: s.rating > 0 ? const Color(0xFFF59E0B) : Colors.white24),
                                  const SizedBox(width: 3),
                                  Text(s.rating.toStringAsFixed(1), style: TextStyle(color: s.rating > 0 ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                                ]),
                                // Reviews
                                Text('${s.totalReviews}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                // Power
                                Text(s.powerRatingKw != null ? '${s.powerRatingKw} kW' : '—', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ];
                            }).toList(),
                          ),
                        ],
                      ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),

          const SizedBox(height: 24),

          // Top / Bottom performers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPerformerCard('Top Performers', _getTopPerformers(), const Color(0xFF22C55E), Icons.trending_up)),
              const SizedBox(width: 20),
              Expanded(child: _buildPerformerCard('Needs Attention', _getBottomPerformers(), const Color(0xFFEF4444), Icons.trending_down)),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05),
>>>>>>> origin/main
        ],
      ),
    );
  }
<<<<<<< HEAD
}

class _TrendsChart extends StatelessWidget {
  final List trends;
  const _TrendsChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(
        child: Text('No trend data', style: TextStyle(color: Colors.white38)),
      );
    }

    // Find max values for normalization
    final double maxRentals = trends.isEmpty ? 10 : trends.map((e) => e.rentals.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
    final double maxRevenue = trends.isEmpty ? 100 : trends.map((e) => e.revenue.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(label: 'Rentals', color: Colors.blue),
              const SizedBox(width: 24),
              _LegendItem(label: 'Revenue', color: const Color(0xFF10B981)),
            ],
          ),
        ),
        
        Expanded(
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E293B),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isRevenue = spot.barIndex == 1;
                      final actualValue = isRevenue 
                        ? trends[spot.spotIndex].revenue 
                        : trends[spot.spotIndex].rentals;
                      
                      return LineTooltipItem(
                        isRevenue 
                          ? 'Revenue: ₹${actualValue.toStringAsFixed(0)}'
                          : 'Rentals: ${actualValue.toInt().toString()}',
                        GoogleFonts.inter(
                          color: spot.bar.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Map standardized 0-100 scale back to revenue
                      final rev = (value / 100) * maxRevenue;
                      if (value % 25 != 0) return const SizedBox.shrink();
                      return Text(
                        '₹${(rev/1000).toStringAsFixed(1)}k',
                        style: const TextStyle(color: Colors.white38, fontSize: 9),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      // Map standardized 0-100 scale back to rentals
                      final rent = (value / 100) * maxRentals;
                      if (value % 25 != 0) return const SizedBox.shrink();
                      return Text(
                        rent.toInt().toString(),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trends.length || value.toInt() < 0) return const SizedBox.shrink();
                      final date = DateTime.parse(trends[value.toInt()].date);
                      // Only show every other label if many points
                      if (trends.length > 7 && value.toInt() % 2 != 0) return const SizedBox.shrink();
                      return Text(
                        DateFormat('MM/dd').format(date),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                // Rentals Line (normalized to 0-100)
                LineChartBarData(
                  spots: trends.asMap().entries.map((e) {
                    final normalized = (e.value.rentals / maxRentals) * 100;
                    return FlSpot(e.key.toDouble(), normalized);
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.blue,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.2),
                        Colors.blue.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Revenue Line (normalized to 0-100)
                LineChartBarData(
                  spots: trends.asMap().entries.map((e) {
                    final normalized = (e.value.revenue / maxRevenue) * 100;
                    return FlSpot(e.key.toDouble(), normalized);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF10B981),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFF10B981),
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.2),
                        const Color(0xFF10B981).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}


class _PeakHoursChart extends StatelessWidget {
  final List peakHours;
  const _PeakHoursChart({required this.peakHours});

  @override
  Widget build(BuildContext context) {
    if (peakHours.isEmpty) {
      return const Center(child: Text('No peak hour data', style: TextStyle(color: Colors.white38)));
    }

    // Find the peak hour to highlight it
    final maxCount = peakHours.isNotEmpty 
        ? peakHours.map((p) => p.rentalCount).reduce((a, b) => a > b ? a : b) 
        : 0;

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E293B),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${group.x}h: ${rod.toY.toInt()} rentals',
                GoogleFonts.inter(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: peakHours.map((p) {
          final isPeak = p.rentalCount == maxCount && maxCount > 0;
          return BarChartGroupData(
            x: p.hour,
            barRods: [
              BarChartRodData(
                toY: p.rentalCount.toDouble(),
                color: isPeak ? Colors.amber : Colors.blueAccent.withValues(alpha: 0.8),
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxCount.toDouble(),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 4 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt()}h',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
=======

  Widget _buildRefreshButton() => Container(
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70, size: 20), onPressed: _loadData, tooltip: 'Refresh'),
  );

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

  Widget _utilizationBar(double pct) {
    Color barColor;
    if (pct >= 80) barColor = const Color(0xFFEF4444);
    else if (pct >= 50) barColor = const Color(0xFFF59E0B);
    else barColor = const Color(0xFF22C55E);

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 60, height: 8, child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct / 100, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(barColor)),
      )),
      const SizedBox(width: 6),
      Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  List<StationPerformance> _getTopPerformers() {
    final sorted = [..._stations]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  List<StationPerformance> _getBottomPerformers() {
    final sorted = [..._stations]..sort((a, b) => a.utilizationPercentage.compareTo(b.utilizationPercentage));
    return sorted.where((s) => s.status.toUpperCase() != 'CLOSED').take(5).toList();
  }

  Widget _buildPerformerCard(String title, List<StationPerformance> items, Color color, IconData icon) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No data', style: GoogleFonts.inter(color: Colors.white54)),
            ))
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.stationName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(s.city ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(s.rating.toStringAsFixed(1), style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                    Text('${s.utilizationPercentage.toStringAsFixed(0)}% util', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                  ]),
                ]),
              );
            }),
>>>>>>> origin/main
        ],
      ),
    );
  }
}
