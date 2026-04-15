import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/fraud_risk.dart';
import '../data/repositories/user_analytics_repository.dart';
import '../provider/user_provider.dart';

class FraudRiskView extends ConsumerStatefulWidget {
  const FraudRiskView({super.key});

  @override
  ConsumerState<FraudRiskView> createState() => _FraudRiskViewState();
}

class _FraudRiskViewState extends ConsumerState<FraudRiskView> {
  late UserAnalyticsRepository _repository;
  List<FraudRisk> _risks = [];
  FraudRisk? _selectedRisk;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(userAnalyticsRepositoryProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    final risks = await _repository.getFraudRisks();
    setState(() {
      _risks = risks;
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
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Fraud Risk Monitoring', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              
              _buildOverviewChip('Critical', _risks.where((r) => r.level == 'critical').length, Colors.red),
              const SizedBox(width: 8),
              _buildOverviewChip('High', _risks.where((r) => r.level == 'high').length, Colors.orange),
              const SizedBox(width: 8),
              _buildOverviewChip('Medium', _risks.where((r) => r.level == 'medium').length, Colors.amber),
              const SizedBox(width: 8),
              _buildOverviewChip('Low', _risks.where((r) => r.level == 'low').length, Colors.green),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk List
              SizedBox(
                width: 400,
                child: Column(
                  children: _risks.map((risk) {
                    final isSelected = _selectedRisk?.userId == risk.userId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRisk = risk),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _riskColor(risk.level).withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? _riskColor(risk.level).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            // Risk gauge mini
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: risk.score / 100,
                                    strokeWidth: 5,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation(_riskColor(risk.level)),
                                  ),
                                  Text('${risk.score}', style: GoogleFonts.outfit(color: _riskColor(risk.level), fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(risk.userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  _buildRiskBadge(risk.level),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 20),

              // Detail panel
              Expanded(child: _selectedRisk != null ? _buildDetailPanel(_selectedRisk!) : _buildEmptyDetail()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(FraudRisk risk) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: risk.score / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(_riskColor(risk.level)),
                    ),
                    Text('${risk.score}', style: GoogleFonts.outfit(color: _riskColor(risk.level), fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(risk.userName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        _buildRiskBadge(risk.level),
                        const SizedBox(width: 8),
                        Text('User #${risk.userId}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Adjust Score'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Risk Factors
          Text('Risk Factors', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...risk.factors.map((factor) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _severityColor(factor.severity).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _severityColor(factor.severity).withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _severityColor(factor.severity).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber, color: _severityColor(factor.severity), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(factor.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(factor.description, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor(factor.severity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('+${factor.contribution}', style: GoogleFonts.inter(color: _severityColor(factor.severity), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),

          // Score History Chart
          if (risk.history.isNotEmpty) ...[
            Text('Score History', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05))),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                    )),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: risk.history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble())).toList(),
                      isCurved: true,
                      color: _riskColor(risk.level),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: _riskColor(risk.level), strokeWidth: 0),
                      ),
                      belowBarData: BarAreaData(show: true, color: _riskColor(risk.level).withValues(alpha: 0.1)),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDetail() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text('Select a user to view risk details', style: GoogleFonts.inter(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label', style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String level) {
    final color = _riskColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(level.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.amber;
      default: return Colors.grey;
    }
  }
}
