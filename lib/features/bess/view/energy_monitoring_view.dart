import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/bess_models.dart';
import '../data/repositories/bess_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class EnergyMonitoringView extends StatefulWidget {
  const EnergyMonitoringView({super.key});
  @override
  State<EnergyMonitoringView> createState() => _EnergyMonitoringViewState();
}

class _EnergyMonitoringViewState extends State<EnergyMonitoringView> {
  final BessRepository _repo = BessRepository();
  List<BessEnergyLog> _logs = [];
  List<Map<String, dynamic>> _summary = [];
  List<BessUnit> _units = [];
  bool _isLoading = true;
  int? _selectedUnitId;
  int _hours = 24;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getEnergyLogs(bessUnitId: _selectedUnitId, hours: _hours),
        _repo.getEnergySummary(days: 7),
        _repo.getUnits(),
      ]);
      setState(() {
        _logs = results[0] as List<BessEnergyLog>;
        _summary = results[1] as List<Map<String, dynamic>>;
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
        title: 'Energy Monitoring',
        subtitle: 'Real-time charge/discharge monitoring',
        actionButton: Row(children: [
          _buildUnitFilter(),
          const SizedBox(width: 12),
          _buildTimeFilter(),
        ]),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

      // Summary cards
      if (_summary.isNotEmpty) _buildDailySummary(),
      const SizedBox(height: 24),

      // Energy logs table
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLogsTable(),
    ]));
  }

  Widget _buildUnitFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
        value: _selectedUnitId,
        hint: Text('All Units', style: TextStyle(color: Colors.white38)),
        dropdownColor: const Color(0xFF1E293B),
        style: TextStyle(color: Colors.white),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Units')),
          ..._units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
        ],
        onChanged: (val) { setState(() => _selectedUnitId = val); _loadData(); },
      )),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<int>(
        value: _hours,
        dropdownColor: const Color(0xFF1E293B),
        style: TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 6, child: Text('Last 6h')),
          DropdownMenuItem(value: 24, child: Text('Last 24h')),
          DropdownMenuItem(value: 48, child: Text('Last 48h')),
          DropdownMenuItem(value: 168, child: Text('Last 7d')),
        ],
        onChanged: (val) { setState(() => _hours = val!); _loadData(); },
      )),
    );
  }

  Widget _buildDailySummary() {
    return AdvancedCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('7-Day Energy Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(height: 160, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _summary.map((day) {
          final charged = (day['charged'] as num?)?.toDouble() ?? 0;
          final discharged = (day['discharged'] as num?)?.toDouble() ?? 0;
          final maxVal = _summary.fold<double>(0, (m, d) => [m, (d['charged'] as num?)?.toDouble() ?? 0, (d['discharged'] as num?)?.toDouble() ?? 0].reduce((a, b) => a > b ? a : b));
          return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 14, height: maxVal > 0 ? (charged / maxVal * 120) : 0, decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 2),
              Container(width: 14, height: maxVal > 0 ? (discharged / maxVal * 120) : 0, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(3))),
            ]),
            const SizedBox(height: 8),
            Text(day['date']?.toString().substring(5) ?? '', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ])));
        }).toList())),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4), Text('Charged', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(width: 16),
          Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4), Text('Discharged', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ]),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildLogsTable() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Text('Energy Logs (${_logs.length} records)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const Spacer(),
          Text('Showing last $_hours hours', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
        _logs.isEmpty
            ? const SizedBox(height: 200, child: Center(child: Text('No energy logs found.', style: TextStyle(color: Colors.white54))))
            : AdvancedTable(
                columns: const ['Time', 'Unit', 'Power (kW)', 'Energy (kWh)', 'SoC Start', 'SoC End', 'Source'],
                rows: _logs.take(50).map((log) {
                  final isCharging = log.powerKw >= 0;
                  final unit = _units.where((u) => u.id == log.bessUnitId).firstOrNull;
                  return [
                    Text(_formatTimestamp(log.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(unit?.name ?? 'Unit ${log.bessUnitId}', style: const TextStyle(color: Colors.white)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isCharging ? Icons.arrow_upward : Icons.arrow_downward, color: isCharging ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 4),
                      Text(log.powerKw.abs().toStringAsFixed(1), style: TextStyle(color: isCharging ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))),
                    ]),
                    Text(log.energyKwh.toStringAsFixed(2), style: const TextStyle(color: Colors.white)),
                    Text('${log.socStart.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white54)),
                    Text('${log.socEnd.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white54)),
                    _sourceBadge(log.source),
                  ];
                }).toList(),
              ),
      ]),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _sourceBadge(String source) {
    final color = source == 'solar' ? const Color(0xFFFBBF24) : source == 'wind' ? const Color(0xFF14B8A6) : const Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(source.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ts; }
  }
}
