import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/bess_models.dart';
import '../data/repositories/bess_repository.dart';

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
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Energy Monitoring', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Real-time charge/discharge monitoring', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        _buildUnitFilter(),
        const SizedBox(width: 12),
        _buildTimeFilter(),
      ]),
      const SizedBox(height: 24),

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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
        value: _selectedUnitId,
        hint: Text('All Units', style: GoogleFonts.inter(color: Colors.white38)),
        dropdownColor: const Color(0xFF1E293B),
        style: GoogleFonts.inter(color: Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(child: DropdownButton<int>(
        value: _hours,
        dropdownColor: const Color(0xFF1E293B),
        style: GoogleFonts.inter(color: Colors.white),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('7-Day Energy Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(height: 160, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _summary.map((day) {
          final charged = (day['charged'] as num?)?.toDouble() ?? 0;
          final discharged = (day['discharged'] as num?)?.toDouble() ?? 0;
          final maxVal = _summary.fold<double>(0, (m, d) => [m, (d['charged'] as num?)?.toDouble() ?? 0, (d['discharged'] as num?)?.toDouble() ?? 0].reduce((a, b) => a > b ? a : b));
          return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 14, height: maxVal > 0 ? (charged / maxVal * 120) : 0, decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 2),
              Container(width: 14, height: maxVal > 0 ? (discharged / maxVal * 120) : 0, decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(3))),
            ]),
            const SizedBox(height: 8),
            Text(day['date']?.toString().substring(5) ?? '', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
          ])));
        }).toList())),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4), Text('Charged', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
          const SizedBox(width: 16),
          Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4), Text('Discharged', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildLogsTable() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,children: [
          Text('Energy Logs (${_logs.length} records)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          
          Text('Showing last $_hours hours', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        ])),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.03)),
          columns: const [
            DataColumn(label: Text('Time', style: TextStyle(color: Colors.white70))),
            DataColumn(label: Text('Unit', style: TextStyle(color: Colors.white70))),
            DataColumn(label: Text('Power (kW)', style: TextStyle(color: Colors.white70))),
            DataColumn(label: Text('Energy (kWh)', style: TextStyle(color: Colors.white70))),
            DataColumn(label: Text('SoC Start', style: TextStyle(color: Colors.white70))),
            DataColumn(label: Text('SoC End', style: TextStyle(color: Colors.white70))),
            DataColumn(label: Text('Source', style: TextStyle(color: Colors.white70))),
          ],
          rows: _logs.take(50).map((log) {
            final isCharging = log.powerKw >= 0;
            final unit = _units.where((u) => u.id == log.bessUnitId).firstOrNull;
            return DataRow(cells: [
              DataCell(Text(_formatTimestamp(log.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12))),
              DataCell(Text(unit?.name ?? 'Unit ${log.bessUnitId}', style: const TextStyle(color: Colors.white))),
              DataCell(Row(children: [
                Icon(isCharging ? Icons.arrow_upward : Icons.arrow_downward, color: isCharging ? Colors.green : Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(log.powerKw.abs().toStringAsFixed(1), style: TextStyle(color: isCharging ? Colors.green : Colors.orange)),
              ])),
              DataCell(Text(log.energyKwh.toStringAsFixed(2), style: const TextStyle(color: Colors.white))),
              DataCell(Text('${log.socStart.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white54))),
              DataCell(Text('${log.socEnd.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white54))),
              DataCell(_sourceBadge(log.source)),
            ]);
          }).toList(),
        )),
      ]),
    );
  }

  Widget _sourceBadge(String source) {
    final color = source == 'solar' ? Colors.amber : source == 'wind' ? Colors.teal : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(source.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ts; }
  }
}
