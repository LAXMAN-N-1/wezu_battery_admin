import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/repositories/kyc_repository.dart';

class KycDashboardView extends StatefulWidget {
  const KycDashboardView({super.key});

  @override
  State<KycDashboardView> createState() => _KycDashboardViewState();
}

class _KycDashboardViewState extends State<KycDashboardView> {
  final KycRepository _repository = KycRepository();
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final metrics = await _repository.getKycMetrics();
    setState(() {
      _metrics = metrics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KYC Dashboard', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),

          // Metric Cards
          Row(
            children: [
              _buildMetricCard('Pending', '${_metrics['pending']}', Icons.pending_actions, Colors.orange),
              const SizedBox(width: 16),
              _buildMetricCard('Approved', '${_metrics['approved']}', Icons.check_circle_outline, Colors.green),
              const SizedBox(width: 16),
              _buildMetricCard('Rejected', '${_metrics['rejected']}', Icons.cancel_outlined, Colors.red),
              const SizedBox(width: 16),
              _buildMetricCard('Manual Review', '${_metrics['manual_review']}', Icons.rate_review_outlined, Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard('Approval Rate', '${_metrics['approval_rate']}%', Icons.trending_up, Colors.green),
              const SizedBox(width: 16),
              _buildMetricCard('Avg Processing', '${_metrics['avg_processing_hours']}h', Icons.timer_outlined, Colors.blue),
              const SizedBox(width: 16),
              _buildMetricCard('Total Submissions', '${_metrics['total']}', Icons.description_outlined, Colors.purple),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
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
                      Text('Status Distribution', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(value: (_metrics['approved'] as num?)?.toDouble() ?? 0, color: Colors.green, title: '${_metrics['approved']}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
                              PieChartSectionData(value: (_metrics['pending'] as num?)?.toDouble() ?? 0, color: Colors.orange, title: '${_metrics['pending']}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
                              PieChartSectionData(value: (_metrics['rejected'] as num?)?.toDouble() ?? 0, color: Colors.red, title: '${_metrics['rejected']}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
                              PieChartSectionData(value: (_metrics['manual_review'] as num?)?.toDouble() ?? 0, color: Colors.amber, title: '${_metrics['manual_review']}', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), radius: 50),
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
                          const SizedBox(width: 16),
                          _buildLegend('Review', Colors.amber),
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
                      Text('Weekly Submissions Trend', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: () {
                              final trendData = _metrics['submission_trend'];
                              final Map<String, dynamic> trend = trendData is Map ? Map<String, dynamic>.from(trendData) : {};
                              final dates = trend.keys.toList()..sort();
                              // Take last 7 days or less
                              final recentDates = dates.length > 7 ? dates.sublist(dates.length - 7) : dates;
                              
                              return List.generate(recentDates.length, (i) {
                                final date = recentDates[i];
                                final count = (trend[date] as num?) ?? 0;
                                return BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(toY: count.toDouble(), color: Colors.blue, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                                ]);
                              });
                            }(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final trendData = _metrics['submission_trend'];
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
