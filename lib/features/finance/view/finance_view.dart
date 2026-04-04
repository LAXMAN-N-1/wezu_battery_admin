import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/transaction.dart';
import '../data/repositories/finance_repository.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({super.key});
  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  final FinanceRepository _repository = FinanceRepository();
  bool _isLoading = true;
  String _period = '30d';
  double _totalRevenue = 0, _periodRevenue = 0, _monthlyGrowth = 0, _successRate = 0;
  int _totalTransactions = 0;
  List<Map<String, dynamic>> _chartData = [], _revenueByType = [];
  List<Transaction> _transactions = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _repository.getFinanceDashboardData(period: _period);
    setState(() {
      _totalRevenue = data['totalRevenue'];
      _periodRevenue = data['periodRevenue'];
      _monthlyGrowth = data['monthlyGrowth'];
      _chartData = List<Map<String, dynamic>>.from(data['revenueChart']);
      _revenueByType = List<Map<String, dynamic>>.from(data['revenueByType']);
      _transactions = List<Transaction>.from(data['recentTransactions']);
      _totalTransactions = data['totalTransactions'];
      _successRate = data['successRate'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Revenue Dashboard',
            subtitle: 'Financial overview and growth analytics.',
            actionButton: Row(mainAxisSize: MainAxisSize.min, children: [
              _periodChip('7d', '7 Days'), _periodChip('30d', '30 Days'),
              _periodChip('90d', '90 Days'), _periodChip('1y', '1 Year'),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Stats Row
          Row(children: [
            _statCard('Total Revenue', '₹${NumberFormat('#,##0').format(_totalRevenue)}', Icons.account_balance_wallet_outlined, const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            _statCard('Period Revenue', '₹${NumberFormat('#,##0').format(_periodRevenue)}', Icons.trending_up_outlined, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _statCard('Growth', '${_monthlyGrowth >= 0 ? "+" : ""}$_monthlyGrowth%', Icons.show_chart_outlined, _monthlyGrowth >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            const SizedBox(width: 12),
            _statCard('Transactions', '$_totalTransactions', Icons.receipt_long_outlined, const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            _statCard('Success Rate', '${_successRate.toStringAsFixed(1)}%', Icons.check_circle_outline, const Color(0xFF14B8A6)),
          ]).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Charts Row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Revenue Chart
            Expanded(flex: 3, child: AdvancedCard(
              height: 320,
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly Revenue Trend', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Expanded(child: _buildLineChart()),
              ]),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms)),
            const SizedBox(width: 16),

            // Revenue By Type
            Expanded(flex: 2, child: AdvancedCard(
              height: 320,
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Revenue by Type', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Expanded(child: _revenueByType.isEmpty
                  ? const Center(child: Text('No data', style: TextStyle(color: Colors.white38)))
                  : _buildTypeBreakdown(),
                ),
              ]),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms)),
          ]),
          const SizedBox(height: 24),

          // Recent Transactions
          Text('Recent Transactions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: AdvancedTable(
              columns: const ['ID', 'User', 'Type', 'Amount', 'Status', 'Date'],
              rows: _transactions.map((tx) => [
                Text(tx.id.length > 8 ? '${tx.id.substring(0, 8)}...' : tx.id, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(tx.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                _typeBadge(tx.type),
                Text('₹${tx.amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                StatusBadge(status: tx.status),
                Text(DateFormat('MMM d, h:mm a').format(tx.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]).toList(),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
        ],
      ),
    );
  }

  Widget _periodChip(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: FilterChip(
      selected: _period == value,
      label: Text(label, style: TextStyle(color: _period == value ? Colors.white : Colors.white54, fontSize: 11)),
      selectedColor: const Color(0xFF3B82F6), backgroundColor: const Color(0xFF1E293B),
      onSelected: (_) { _period = value; _loadData(); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.transparent)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
  );

  Widget _statCard(String title, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
        Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
      ])),
    ])),
  );

  Widget _typeBadge(String type) {
    final colors = {'RENTAL_PAYMENT': const Color(0xFF3B82F6), 'SUBSCRIPTION': const Color(0xFF8B5CF6), 'PURCHASE': const Color(0xFF22C55E), 'REFUND': const Color(0xFFEF4444), 'SWAP_FEE': const Color(0xFF14B8A6)};
    final c = colors[type.toUpperCase()] ?? const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(type.replaceAll('_', ' '), style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLineChart() {
    if (_chartData.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.white38)));
    final maxY = _chartData.map((d) => (d['value'] as num).toDouble()).fold<double>(0, (p, e) => e > p ? e : p) * 1.2;

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1)),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1,
          getTitlesWidget: (v, m) => v.toInt() >= 0 && v.toInt() < _chartData.length
            ? SideTitleWidget(meta: m, child: Text(_chartData[v.toInt()]['month'], style: const TextStyle(color: Colors.white54, fontSize: 11)))
            : const SizedBox(),
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48,
          getTitlesWidget: (v, m) => Text('₹${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        )),
      ),
      borderData: FlBorderData(show: false),
      minX: 0, maxX: _chartData.length.toDouble() - 1, minY: 0, maxY: maxY,
      lineBarsData: [LineChartBarData(
        spots: _chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
        isCurved: true, color: const Color(0xFF3B82F6), barWidth: 3, isStrokeCapRound: true,
        dotData: FlDotData(show: true, getDotPainter: (s, p, d, i) => FlDotCirclePainter(radius: 4, color: const Color(0xFF3B82F6), strokeWidth: 2, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF3B82F6).withValues(alpha: 0.3), const Color(0xFF3B82F6).withValues(alpha: 0.0)])),
      )],
    ));
  }

  Widget _buildTypeBreakdown() {
    final total = _revenueByType.fold<double>(0, (s, d) => s + (d['amount'] as num).toDouble());
    final colors = [const Color(0xFF3B82F6), const Color(0xFF22C55E), const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF14B8A6), const Color(0xFFF97316)];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _revenueByType.length,
      itemBuilder: (ctx, i) {
        final d = _revenueByType[i];
        final amt = (d['amount'] as num).toDouble();
        final pct = total > 0 ? (amt / total * 100) : 0.0;
        final c = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Text((d['type'] as String).replaceAll('_', ' '), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              Text('₹${NumberFormat('#,##0').format(amt)}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.05), valueColor: AlwaysStoppedAnimation(c)),
            ),
          ]),
        );
      },
    );
  }
}
