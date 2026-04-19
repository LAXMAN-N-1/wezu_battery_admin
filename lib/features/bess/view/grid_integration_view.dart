import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/bess_models.dart';
import '../data/repositories/bess_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

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
      PageHeader(
        title: 'Grid Integration',
        subtitle: 'Peak shaving, load shifting, and grid event management',
        actionButton: ElevatedButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Grid Event'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

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
      ]).animate().fadeIn(duration: 400.ms, delay: 150.ms),
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
      _summaryCard('Revenue Earned', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, const Color(0xFF22C55E)),
      _summaryCard('Energy Traded', '${totalEnergy.toStringAsFixed(0)} kWh', Icons.swap_horiz, const Color(0xFFF59E0B)),
      _summaryCard('Active / Scheduled', '$active / $scheduled', Icons.schedule, const Color(0xFF8B5CF6)),
    ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return AdvancedCard(
      width: 220,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06))),
      child: Text(label, style: TextStyle(color: selected ? const Color(0xFF3B82F6) : Colors.white54, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
    ));
  }

  Widget _statusFilter() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
        value: _filterStatus, hint: Text('All Status', style: TextStyle(color: Colors.white38, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), style: TextStyle(color: Colors.white, fontSize: 13),
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
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: _events.isEmpty
          ? const SizedBox(height: 300, child: Center(child: Text('No grid events found.', style: TextStyle(color: Colors.white54))))
          : AdvancedTable(
              columns: const ['Type', 'Unit', 'Status', 'Start', 'Power (kW)', 'Energy (kWh)', 'Revenue', 'Operator'],
              rows: _events.map((e) {
                final unit = _units.where((u) => u.id == e.bessUnitId).firstOrNull;
                return [
                  _typeBadge(e.eventType),
                  Text(unit?.name ?? '—', style: const TextStyle(color: Colors.white)),
                  StatusBadge(status: e.status),
                  Text(_formatTs(e.startTime), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(e.actualPowerKw?.toStringAsFixed(1) ?? e.targetPowerKw.toStringAsFixed(1), style: const TextStyle(color: Colors.white)),
                  Text(e.energyKwh?.toStringAsFixed(1) ?? '—', style: const TextStyle(color: Colors.white54)),
                  Text(e.revenueEarned != null ? '₹${e.revenueEarned!.toStringAsFixed(0)}' : '—', style: TextStyle(color: e.revenueEarned != null ? const Color(0xFF22C55E) : Colors.white38)),
                  Text(e.gridOperator ?? '—', style: const TextStyle(color: Colors.white54)),
                ];
              }).toList(),
            ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _typeBadge(String type) {
    final color = type == 'peak_shaving' ? const Color(0xFFF59E0B) : type == 'load_shifting' ? const Color(0xFF3B82F6) : type == 'frequency_regulation' ? const Color(0xFF8B5CF6) : const Color(0xFF14B8A6);
    final label = type.replaceAll('_', ' ');
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)));
  }

  String _formatTs(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }

  void _showCreateDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('New Grid Event', style: GoogleFonts.outfit(color: Colors.white)),
      content: Text('Grid event creation coming soon.', style: TextStyle(color: Colors.white54)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
}
