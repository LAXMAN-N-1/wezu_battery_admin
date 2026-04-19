import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/bess_models.dart';
import '../data/repositories/bess_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class BessReportsView extends StatefulWidget {
  const BessReportsView({super.key});
  @override
  State<BessReportsView> createState() => _BessReportsViewState();
}

class _BessReportsViewState extends State<BessReportsView> {
  final BessRepository _repo = BessRepository();
  List<BessReport> _reports = [];
  Map<String, dynamic> _kpi = {};
  List<BessUnit> _units = [];
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getReports(reportType: _filterType),
        _repo.getReportsKpi(),
        _repo.getUnits(),
      ]);
      setState(() {
        _reports = results[0] as List<BessReport>;
        _kpi = results[1] as Map<String, dynamic>;
        _units = results[2] as List<BessUnit>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: 'BESS Reports',
        subtitle: 'Energy storage performance reports and efficiency metrics',
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

      // KPI Cards
      if (_kpi.isNotEmpty) _buildKpiCards(),
      const SizedBox(height: 24),

      // Filter
      Row(children: [
        Text('Report History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
            value: _filterType, hint: Text('All Types', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
            dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Types')),
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
            onChanged: (val) { setState(() => _filterType = val); _loadData(); },
          ))),
      ]).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      const SizedBox(height: 16),

      _isLoading ? const Center(child: CircularProgressIndicator()) : _buildReportsTable(),
    ]));
  }

  Widget _buildKpiCards() {
    final charged = (_kpi['total_charged'] as num?)?.toDouble() ?? 0;
    final discharged = (_kpi['total_discharged'] as num?)?.toDouble() ?? 0;
    final efficiency = (_kpi['avg_efficiency'] as num?)?.toDouble() ?? 0;
    final revenue = (_kpi['total_revenue'] as num?)?.toDouble() ?? 0;
    final cost = (_kpi['total_cost'] as num?)?.toDouble() ?? 0;
    final profit = revenue - cost;

    return Wrap(spacing: 16, runSpacing: 16, children: [
      _kpiCard('Total Charged', '${(charged / 1000).toStringAsFixed(1)} MWh', Icons.battery_charging_full, const Color(0xFF10B981)),
      _kpiCard('Total Discharged', '${(discharged / 1000).toStringAsFixed(1)} MWh', Icons.battery_alert, const Color(0xFFF59E0B)),
      _kpiCard('Avg Efficiency', '${efficiency.toStringAsFixed(1)}%', Icons.speed, const Color(0xFF3B82F6)),
      _kpiCard('Total Revenue', '₹${(revenue / 1000).toStringAsFixed(1)}K', Icons.trending_up, const Color(0xFF10B981)),
      _kpiCard('Total Cost', '₹${(cost / 1000).toStringAsFixed(1)}K', Icons.trending_down, const Color(0xFFEF4444)),
      _kpiCard('Net Profit', '₹${(profit / 1000).toStringAsFixed(1)}K', Icons.account_balance, profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
    ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return AdvancedCard(
      width: 200,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _buildReportsTable() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: _reports.isEmpty
          ? const SizedBox(height: 300, child: Center(child: Text('No reports found.', style: TextStyle(color: Colors.white54))))
          : AdvancedTable(
              columns: const ['Period', 'Type', 'Unit', 'Charged', 'Discharged', 'Efficiency', 'Revenue', 'Cost', 'Events'],
              rows: _reports.map((r) {
                final unit = r.bessUnitId != null ? _units.where((u) => u.id == r.bessUnitId).firstOrNull : null;
                final effColor = r.avgEfficiency > 90 ? const Color(0xFF22C55E) : r.avgEfficiency > 80 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
                return [
                  Text('${_formatDate(r.periodStart)} — ${_formatDate(r.periodEnd)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  StatusBadge(status: r.reportType),
                  Text(unit?.name ?? 'All', style: const TextStyle(color: Colors.white54)),
                  Text('${r.totalChargedKwh.toStringAsFixed(0)} kWh', style: const TextStyle(color: Color(0xFF22C55E))),
                  Text('${r.totalDischargedKwh.toStringAsFixed(0)} kWh', style: const TextStyle(color: Color(0xFFF59E0B))),
                  Text('${r.avgEfficiency.toStringAsFixed(1)}%', style: TextStyle(color: effColor, fontWeight: FontWeight.w600)),
                  Text('₹${r.revenue.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF22C55E))),
                  Text('₹${r.cost.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFEF4444))),
                  Text('${r.gridEventsCount}', style: const TextStyle(color: Colors.white54)),
                ];
              }).toList(),
            ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  String _formatDate(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.month}/${dt.day}'; } catch (_) { return ts; }
  }
}
