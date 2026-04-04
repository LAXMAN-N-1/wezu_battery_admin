import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../provider/kyc_provider.dart';

class KycDashboardView extends ConsumerStatefulWidget {
  const KycDashboardView({super.key});

  @override
  ConsumerState<KycDashboardView> createState() => _KycDashboardViewState();
}

class _KycDashboardViewState extends ConsumerState<KycDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);
    final metrics = kycState.dashboard;

    if (kycState.isLoading && metrics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KYC Dashboard', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(
                onPressed: () => ref.read(kycProvider.notifier).loadDashboard(),
                icon: const Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'Refresh Dashboard',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metric Cards
          Row(
            children: [
              _buildMetricCard('Pending', '${metrics['total_pending'] ?? 0}', Icons.pending_actions, Colors.orange),
              const SizedBox(width: 16),
              _buildMetricCard('Approved (Today)', '${metrics['total_approved_today'] ?? 0}', Icons.check_circle_outline, Colors.green),
              const SizedBox(width: 16),
              _buildMetricCard('Rejected (Today)', '${metrics['total_rejected_today'] ?? 0}', Icons.cancel_outlined, Colors.red),
              const SizedBox(width: 16),
              _buildMetricCard('Total (Active)', '${(metrics['total_pending'] ?? 0) + (metrics['total_approved_today'] ?? 0)}', Icons.description_outlined, Colors.purple),
            ],
          ),
          const SizedBox(height: 28),

          // Charts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Distribution Pie Chart
              Expanded(
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Performance', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(value: (metrics['total_approved_today'] as num?)?.toDouble() ?? 0, color: Colors.green, title: '${metrics['total_approved_today'] ?? 0}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
                              PieChartSectionData(value: (metrics['total_pending'] as num?)?.toDouble() ?? 0, color: Colors.orange, title: '${metrics['total_pending'] ?? 0}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
                              PieChartSectionData(value: (metrics['total_rejected_today'] as num?)?.toDouble() ?? 0, color: Colors.red, title: '${metrics['total_rejected_today'] ?? 0}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend('Approved', Colors.green),
                          const SizedBox(width: 16),
                          _buildLegend('Pending', Colors.orange),
                          const SizedBox(width: 16),
                          _buildLegend('Rejected', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Trend Chart
              Expanded(
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submission Trend', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: () {
                              final trendData = metrics['submission_trend'];
                              final Map<String, dynamic> trend = trendData is Map ? Map<String, dynamic>.from(trendData) : {};
                              final dates = trend.keys.toList()..sort();
                              // Take last 7 days or less
                              final recentDates = dates.length > 7 ? dates.sublist(dates.length - 7) : dates;
                              
                              return List.generate(recentDates.length, (i) {
                                final date = recentDates[i];
                                final count = (trend[date] as num?) ?? 0;
                                final barColor = _getChartColor(i);
                                return BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: count.toDouble(),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        barColor,
                                        barColor.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ]);
                              });
                            }(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final trendData = metrics['submission_trend'];
                                  final Map<String, dynamic> trend = trendData is Map ? Map<String, dynamic>.from(trendData) : {};
                                  final dates = trend.keys.toList()..sort();
                                  final recentDates = dates.length > 7 ? dates.sublist(dates.length - 7) : dates;
                                  
                                  if (value.toInt() >= recentDates.length) return const SizedBox();
                                  
                                  // Format date string (usually YYYY-MM-DD to MM/DD)
                                  final dateStr = recentDates[value.toInt()];
                                  final label = dateStr.contains('-') ? dateStr.substring(5) : dateStr;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                                  );
                                },
                              )),
                              leftTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                              )),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(int index) {
    final palette = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.cyan,
      Colors.pink,
    ];
    return palette[index % palette.length];
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
