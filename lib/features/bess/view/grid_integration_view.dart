import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/bess_models.dart';
import '../data/repositories/bess_repository.dart';

class GridIntegrationView extends StatefulWidget {
  const GridIntegrationView({super.key});
  @override
  State<GridIntegrationView> createState() => _GridIntegrationViewState();
}

class _GridIntegrationViewState extends State<GridIntegrationView> {
  final BessRepository _repo = BessRepository();
  List<BessGridEvent> _events = [];
  List<BessUnit> _units = [];
  bool _isLoading = true;
  String? _filterType;
  String? _filterStatus;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getGridEvents(eventType: _filterType),
        _repo.getUnits(),
      ]);
      setState(() {
        _events = results[0] as List<BessGridEvent>;
        _units = results[1] as List<BessUnit>;
        if (_filterStatus != null) _events = _events.where((e) => e.status == _filterStatus).toList();
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
          Text('Grid Integration', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Peak shaving, load shifting, and grid event management', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Grid Event'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
      const SizedBox(height: 24),

      // Summary stats
      _buildSummaryCards(),
      const SizedBox(height: 24),

      // Filters
      Row(children: [
        _filterChip('All', _filterType == null, () { setState(() => _filterType = null); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Peak Shaving', _filterType == 'peak_shaving', () { setState(() => _filterType = 'peak_shaving'); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Load Shifting', _filterType == 'load_shifting', () { setState(() => _filterType = 'load_shifting'); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Freq. Regulation', _filterType == 'frequency_regulation', () { setState(() => _filterType = 'frequency_regulation'); _loadData(); }),
        const SizedBox(width: 8),
        _filterChip('Backup', _filterType == 'backup', () { setState(() => _filterType = 'backup'); _loadData(); }),
        const Spacer(),
        _statusFilter(),
      ]),
      const SizedBox(height: 24),

      _isLoading ? const Center(child: CircularProgressIndicator()) : _buildEventsTable(),
    ]));
  }

  Widget _buildSummaryCards() {
    final completed = _events.where((e) => e.status == 'completed');
    final totalRevenue = completed.fold<double>(0, (sum, e) => sum + (e.revenueEarned ?? 0));
    final totalEnergy = completed.fold<double>(0, (sum, e) => sum + (e.energyKwh ?? 0));
    final scheduled = _events.where((e) => e.status == 'scheduled').length;
    final active = _events.where((e) => e.status == 'active').length;

    return Wrap(spacing: 16, runSpacing: 16, children: [
      _summaryCard('Total Events', '${_events.length}', Icons.grid_on, const Color(0xFF3B82F6)),
      _summaryCard('Revenue Earned', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, const Color(0xFF10B981)),
      _summaryCard('Energy Traded', '${totalEnergy.toStringAsFixed(0)} kWh', Icons.swap_horiz, const Color(0xFFF59E0B)),
      _summaryCard('Active / Scheduled', '$active / $scheduled', Icons.schedule, const Color(0xFF8B5CF6)),
    ]);
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(width: 220, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ]),
      ]));
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : Colors.transparent)),
      child: Text(label, style: GoogleFonts.inter(color: selected ? const Color(0xFF3B82F6) : Colors.white54, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
    ));
  }

  Widget _statusFilter() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
        value: _filterStatus, hint: Text('All Status', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        items: const [
          DropdownMenuItem(value: null, child: Text('All Status')),
          DropdownMenuItem(value: 'completed', child: Text('Completed')),
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
        ],
        onChanged: (val) { setState(() => _filterStatus = val); _loadData(); },
      )));
  }

  Widget _buildEventsTable() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.03)),
        columns: const [
          DataColumn(label: Text('Type', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Unit', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Start', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Power (kW)', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Energy (kWh)', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Revenue', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Operator', style: TextStyle(color: Colors.white70))),
        ],
        rows: _events.map((e) {
          final unit = _units.where((u) => u.id == e.bessUnitId).firstOrNull;
          final statusColor = e.status == 'completed' ? Colors.green : e.status == 'active' ? Colors.blue : e.status == 'scheduled' ? Colors.amber : Colors.grey;
          return DataRow(cells: [
            DataCell(_typeBadge(e.eventType)),
            DataCell(Text(unit?.name ?? '—', style: const TextStyle(color: Colors.white))),
            DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(e.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
            DataCell(Text(_formatTs(e.startTime), style: const TextStyle(color: Colors.white54, fontSize: 12))),
            DataCell(Text(e.actualPowerKw?.toStringAsFixed(1) ?? e.targetPowerKw.toStringAsFixed(1), style: const TextStyle(color: Colors.white))),
            DataCell(Text(e.energyKwh?.toStringAsFixed(1) ?? '—', style: const TextStyle(color: Colors.white54))),
            DataCell(Text(e.revenueEarned != null ? '₹${e.revenueEarned!.toStringAsFixed(0)}' : '—', style: TextStyle(color: e.revenueEarned != null ? Colors.green : Colors.white38))),
            DataCell(Text(e.gridOperator ?? '—', style: const TextStyle(color: Colors.white54))),
          ]);
        }).toList(),
      )),
    );
  }

  Widget _typeBadge(String type) {
    final color = type == 'peak_shaving' ? Colors.orange : type == 'load_shifting' ? Colors.blue : type == 'frequency_regulation' ? Colors.purple : Colors.teal;
    final label = type.replaceAll('_', ' ');
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  String _formatTs(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }

  void _showCreateDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('New Grid Event', style: GoogleFonts.outfit(color: Colors.white)),
      content: Text('Grid event creation coming soon.', style: GoogleFonts.inter(color: Colors.white54)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
}
