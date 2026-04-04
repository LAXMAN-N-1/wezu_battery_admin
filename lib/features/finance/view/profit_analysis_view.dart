import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/finance_repository.dart';

class ProfitAnalysisView extends StatefulWidget {
  const ProfitAnalysisView({super.key});
  @override
  State<ProfitAnalysisView> createState() => _ProfitAnalysisViewState();
}

class _ProfitAnalysisViewState extends State<ProfitAnalysisView> {
  final FinanceRepository _repo = FinanceRepository();
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _repo.getProfitAnalysis();
    setState(() { _data = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final revenue = (_data['total_revenue'] as num?)?.toDouble() ?? 0;
    final commissions = (_data['total_commissions'] as num?)?.toDouble() ?? 0;
    final refunds = (_data['total_refunds'] as num?)?.toDouble() ?? 0;
    final platformFees = (_data['total_platform_fees'] as num?)?.toDouble() ?? 0;
    final grossProfit = (_data['gross_profit'] as num?)?.toDouble() ?? 0;
    final netProfit = (_data['net_profit'] as num?)?.toDouble() ?? 0;
    final margin = (_data['profit_margin'] as num?)?.toDouble() ?? 0;
    final tax = (_data['total_tax_collected'] as num?)?.toDouble() ?? 0;
    final trend = List<Map<String, dynamic>>.from(_data['monthly_trend'] ?? []);
    final byType = List<Map<String, dynamic>>.from(_data['revenue_by_type'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Profit Analysis', subtitle: 'Revenue, costs, margins, and profitability insights.',
          actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),

        // Top Stats
        Row(children: [
          _bigStat('Total Revenue', revenue, const Color(0xFF3B82F6), Icons.trending_up),
          const SizedBox(width: 12),
          _bigStat('Gross Profit', grossProfit, const Color(0xFF22C55E), Icons.show_chart),
          const SizedBox(width: 12),
          _bigStat('Net Profit', netProfit, netProfit >= 0 ? const Color(0xFF14B8A6) : const Color(0xFFEF4444), Icons.account_balance_wallet),
          const SizedBox(width: 12),
          Expanded(child: AdvancedCard(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('Profit Margin', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            Text('${margin.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: margin >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
            const SizedBox(height: 4),
            Container(width: 60, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: 0.1)),
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (margin.clamp(0, 100) / 100),
                child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFF22C55E))))),
          ]))),
        ]).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),

        // Cost Breakdown
        Row(children: [
          _costCard('Commissions', commissions, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _costCard('Refunds', refunds, const Color(0xFFEF4444)),
          const SizedBox(width: 12),
          _costCard('Platform Fees', platformFees, const Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          _costCard('Tax Collected', tax, const Color(0xFF14B8A6)),
        ]).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 24),

        // Charts
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Monthly Trend Chart
          Expanded(flex: 3, child: AdvancedCard(
            height: 360, padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monthly Revenue vs Costs', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(children: [
                _legendDot(const Color(0xFF3B82F6), 'Revenue'),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFFEF4444), 'Costs'),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFF22C55E), 'Profit'),
              ]),
              const SizedBox(height: 16),
              Expanded(child: _buildTrendChart(trend)),
            ]),
          ).animate().fadeIn(delay: 250.ms)),
          const SizedBox(width: 16),

          // Revenue Pie by Type
          Expanded(flex: 2, child: AdvancedCard(
            height: 360, padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Revenue Distribution', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(child: byType.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: Colors.white38)))
                : _buildPieChart(byType)),
            ]),
          ).animate().fadeIn(delay: 300.ms)),
        ]),
        const SizedBox(height: 24),

        // Monthly Breakdown Table
        Text('Monthly P&L Breakdown', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 12),
        AdvancedCard(padding: EdgeInsets.zero, child: AdvancedTable(
          columns: const ['Month', 'Revenue', 'Costs', 'Profit', 'Margin'],
          rows: trend.map((m) {
            final rev = (m['revenue'] as num?)?.toDouble() ?? 0;
            final cost = (m['costs'] as num?)?.toDouble() ?? 0;
            final prof = (m['profit'] as num?)?.toDouble() ?? 0;
            final mg = rev > 0 ? (prof / rev * 100) : 0.0;
            return [
              Text(m['month'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('₹${NumberFormat('#,##0').format(rev)}', style: const TextStyle(color: Color(0xFF3B82F6))),
              Text('₹${NumberFormat('#,##0').format(cost)}', style: const TextStyle(color: Color(0xFFEF4444))),
              Text('₹${NumberFormat('#,##0').format(prof)}', style: TextStyle(color: prof >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              Text('${mg.toStringAsFixed(1)}%', style: TextStyle(color: mg >= 0 ? Colors.white : const Color(0xFFEF4444))),
            ];
          }).toList(),
        )).animate().fadeIn(delay: 400.ms),
      ]),
    );
  }

  Widget _bigStat(String title, double value, Color color, IconData icon) => Expanded(
    child: AdvancedCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11))]),
      const SizedBox(height: 8),
      Text('₹${NumberFormat('#,##0').format(value)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
    ])),
  );

  Widget _costCard(String label, double value, Color color) => Expanded(
    child: AdvancedCard(child: Row(children: [
      Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text('₹${NumberFormat('#,##0').format(value)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
      ])),
    ])),
  );

  Widget _legendDot(Color c, String label) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);

  Widget _buildTrendChart(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.white38)));
    double maxVal = 0;
    for (final m in trend) {
      for (final k in ['revenue', 'costs', 'profit']) {
        final v = (m[k] as num?)?.toDouble() ?? 0;
        if (v.abs() > maxVal) maxVal = v.abs();
      }
    }
    maxVal *= 1.2;

    return BarChart(BarChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxVal / 4, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1)),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) {
          final i = v.toInt();
          return i >= 0 && i < trend.length ? SideTitleWidget(meta: m, child: Text((trend[i]['month'] ?? '').toString().split(' ').first, style: const TextStyle(color: Colors.white54, fontSize: 10))) : const SizedBox();
        })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48, getTitlesWidget: (v, m) => Text('₹${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: Colors.white38, fontSize: 9)))),
      ),
      borderData: FlBorderData(show: false),
      barGroups: trend.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(toY: (e.value['revenue'] as num?)?.toDouble() ?? 0, color: const Color(0xFF3B82F6), width: 8, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
        BarChartRodData(toY: (e.value['costs'] as num?)?.toDouble() ?? 0, color: const Color(0xFFEF4444), width: 8, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
        BarChartRodData(toY: (e.value['profit'] as num?)?.toDouble() ?? 0, color: const Color(0xFF22C55E), width: 8, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
      ])).toList(),
    ));
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    final colors = [const Color(0xFF3B82F6), const Color(0xFF22C55E), const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF14B8A6), const Color(0xFFF97316)];
    final total = data.fold<double>(0, (s, d) => s + (d['amount'] as num).toDouble());

    return Column(children: [
      SizedBox(height: 140, child: PieChart(PieChartData(
        sectionsSpace: 2, centerSpaceRadius: 28,
        sections: data.asMap().entries.map((e) {
          final pct = total > 0 ? ((e.value['amount'] as num).toDouble() / total * 100) : 0.0;
          return PieChartSectionData(
            value: pct, color: colors[e.key % colors.length], radius: 40, showTitle: false,
          );
        }).toList(),
      ))),
      const SizedBox(height: 12),
      ...data.asMap().entries.take(6).map((e) {
        final pct = total > 0 ? ((e.value['amount'] as num).toDouble() / total * 100) : 0.0;
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Expanded(child: Text((e.value['type'] as String).replaceAll('_', ' '), style: const TextStyle(color: Colors.white54, fontSize: 10), overflow: TextOverflow.ellipsis)),
          Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        ]));
      }),
    ]);
  }
}
