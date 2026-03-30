import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/settings_repository.dart';

class SystemHealthView extends StatefulWidget {
  const SystemHealthView({super.key});
  @override State<SystemHealthView> createState() => _SystemHealthViewState();
}

class _SystemHealthViewState extends State<SystemHealthView> {
  final SettingsRepository _repo = SettingsRepository();
  Map<String, dynamic> _health = {};
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _health = await _repo.getSystemHealth(); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('System Health', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Real-time infrastructure monitoring and service status', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _loadData, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 32),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : _buildHealthContent(),
    ]));
  }

  Widget _buildHealthContent() {
    final services = _health['services'] as List? ?? [];
    final system = _health['system'] as Map? ?? {};
    final dbStats = _health['database_stats'] as Map? ?? {};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Service Dependencies', Icons.hub, Column(children: services.map((s) => _serviceCard(s)).toList())),
      const SizedBox(height: 24),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _section('System Information', Icons.memory, Column(children: [
          _infoRow('Host OS', system['os'] ?? 'Unknown'),
          _infoRow('Hostname', system['hostname'] ?? 'Unknown'),
          _infoRow('Python Env', system['python_version'] ?? 'Unknown'),
          _infoRow('Uptime', system['uptime'] ?? 'Unknown'),
        ]))),
        const SizedBox(width: 24),
        Expanded(child: _section('Database Statistics', Icons.storage, Column(children: [
          _infoRow('Registered Users', '${dbStats['users'] ?? 0}'),
          _infoRow('Battery Assets', '${dbStats['batteries'] ?? 0}'),
          _infoRow('Active Stations', '${dbStats['stations'] ?? 0}'),
          _infoRow('Total Rentals', '${dbStats['rentals'] ?? 0}'),
        ]))),
      ]),
    ]);
  }

  Widget _section(String title, IconData icon, Widget content) {
    return Container(padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.blue, size: 24), const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        const SizedBox(height: 24), content,
      ]));
  }

  Widget _serviceCard(dynamic s) {
    final status = s['status']?.toString() ?? 'unknown';
    final name = s['name']?.toString() ?? 'Unknown Service';
    final latency = s['latency_ms'];
    final details = s['details']?.toString();

    final statusColor = status == 'online' ? Colors.green : status == 'standby' ? Colors.orange : status == 'offline' ? Colors.red : Colors.grey;

    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: statusColor, width: 4))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          if (details != null) ...[
            const SizedBox(height: 4), Text(details, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
          ],
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
          ]),
          if (latency != null) ...[
            const SizedBox(height: 4), Text('${latency}ms ping', style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.white38)),
          ],
        ]),
      ]));
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white54))),
      Text(value, style: GoogleFonts.robotoMono(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
    ]));
  }
}
