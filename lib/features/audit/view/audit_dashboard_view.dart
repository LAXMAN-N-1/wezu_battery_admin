import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/audit_repository.dart';

class AuditDashboardView extends StatefulWidget {
  const AuditDashboardView({super.key});
  @override State<AuditDashboardView> createState() => _AuditDashboardViewState();
}

class _AuditDashboardViewState extends State<AuditDashboardView> {
  final AuditRepository _repo = AuditRepository();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _stats = await _repo.getAuditStats(); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Audit & Security Dashboard', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text('High-level overview of system security and audit compliance', style: TextStyle(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 24),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
    ]));
  }

  Widget _buildDashboardContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 16, runSpacing: 16, children: [
        _statCard('Total Logs', '${_stats['total'] ?? 0}', Icons.history, const Color(0xFF3B82F6)),
        _statCard('Logs Today', '${_stats['today'] ?? 0}', Icons.today, const Color(0xFF10B981)),
        _statCard('Logs This Week', '${_stats['this_week'] ?? 0}', Icons.date_range, const Color(0xFF8B5CF6)),
      ]),
      const SizedBox(height: 32),
      Text('Action Breakdown', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 16),
      _buildActionChart(),
    ]);
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(width: 200, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24), const SizedBox(height: 12),
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: TextStyle(color: Colors.white54, fontSize: 13)),
      ]));
  }

  Widget _buildActionChart() {
    final Map<String, dynamic> actions = _stats['by_action'] ?? {};
    if (actions.isEmpty) return const Text('No action data available', style: TextStyle(color: Colors.white54));
    
    final totalSum = actions.values.fold<int>(0, (sum, val) => sum + (val as int));
    return Wrap(spacing: 12, runSpacing: 12, children: actions.entries.map((e) {
      final percentage = totalSum > 0 ? ((e.value as int) / totalSum * 100) : 0;
      return Container(width: 250, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(e.key.toUpperCase(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70))),
            Text('${e.value}', style: GoogleFonts.robotoMono(fontSize: 14, color: Colors.white)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
            value: percentage / 100, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.1), color: Colors.blue,
          )),
        ]));
    }).toList());
  }
}
