import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/audit_models.dart';
import '../data/repositories/audit_repository.dart';

class SecurityEventsView extends StatefulWidget {
  const SecurityEventsView({super.key});
  @override State<SecurityEventsView> createState() => _SecurityEventsViewState();
}

class _SecurityEventsViewState extends State<SecurityEventsView> {
  final AuditRepository _repo = AuditRepository();
  List<SecurityEventItem> _events = [];
  bool _isLoading = true;
  String? _filterSeverity;
  bool? _filterResolved;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getSecurityEvents(severity: _filterSeverity, isResolved: _filterResolved);
      setState(() { _events = res['items'] as List<SecurityEventItem>; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Security Events', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Monitor and resolve potential security threats and anomalies', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 24),
      Row(children: [
        _buildFilter('Severity', _filterSeverity, ['low', 'medium', 'high', 'critical'], (v) { setState(() => _filterSeverity = v); _loadData(); }),
        const SizedBox(width: 12),
        _buildFilterBool('Status', _filterResolved, (v) { setState(() => _filterResolved = v); _loadData(); }),
      ]),
      const SizedBox(height: 24),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : Column(children: _events.map(_buildEventCard).toList()),
    ]));
  }

  Widget _buildFilter(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
        value: value, hint: Text('All $label', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        items: [DropdownMenuItem(value: null, child: Text('All $label')), ...items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase())))],
        onChanged: onChanged)));
  }

  Widget _buildFilterBool(String label, bool? value, Function(bool?) onChanged) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(child: DropdownButton<bool?>(
        value: value, hint: Text('All $label', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        items: const [DropdownMenuItem(value: null, child: Text('All Status')), DropdownMenuItem(value: true, child: Text('RESOLVED')), DropdownMenuItem(value: false, child: Text('UNRESOLVED'))],
        onChanged: onChanged)));
  }

  Widget _buildEventCard(SecurityEventItem event) {
    final severityColor = event.severity == 'critical' ? Colors.red : event.severity == 'high' ? Colors.orange : event.severity == 'medium' ? Colors.amber : Colors.blue;
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.isResolved ? Colors.white.withValues(alpha: 0.06) : severityColor.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: event.isResolved ? Colors.white.withValues(alpha: 0.05) : severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.security, color: event.isResolved ? Colors.white38 : severityColor, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(event.eventType.toUpperCase().replaceAll('_', ' '), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              if (!event.isResolved) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(event.severity.toUpperCase(), style: GoogleFonts.inter(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              if (event.userId != null) ...[
                Icon(Icons.person, size: 12, color: Colors.white38), const SizedBox(width: 4),
                Text('User #${event.userId}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 12),
              ],
              Icon(Icons.computer, size: 12, color: Colors.white38), const SizedBox(width: 4),
              Text(event.sourceIp ?? 'Unknown IP', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 12, color: Colors.white38), const SizedBox(width: 4),
              Text(_formatDate(event.timestamp), style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            ]),
          ])),
          if (!event.isResolved) ElevatedButton.icon(
            onPressed: () async { await _repo.resolveSecurityEvent(event.id); _loadData(); },
            icon: const Icon(Icons.check, size: 16), label: const Text('Resolve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
          if (event.isResolved) Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text('Resolved', style: GoogleFonts.inter(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ]),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), width: double.infinity,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8)),
          child: Text(event.details, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5))),
      ]));
  }

  String _formatDate(String ts) {
    try { final dt = DateTime.parse(ts); final diff = DateTime.now().difference(dt);
      if (diff.inHours < 24) return '${diff.inHours}h ago'; return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }
}
