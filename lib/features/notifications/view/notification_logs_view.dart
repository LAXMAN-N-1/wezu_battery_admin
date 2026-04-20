import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/notification_models.dart';
import '../data/repositories/notification_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class NotificationLogsView extends StatefulWidget {
  const NotificationLogsView({super.key});
  @override State<NotificationLogsView> createState() => _NotificationLogsViewState();
}

class _NotificationLogsViewState extends SafeState<NotificationLogsView> {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationLog> _logs = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _filterChannel;
  String? _filterStatus;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getLogs(channel: _filterChannel, status: _filterStatus),
        _repo.getLogStats(),
      ]);
      _logs = results[0] as List<NotificationLog>;
      _stats = results[1] as Map<String, dynamic>;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: 'Notification Logs',
        subtitle: 'Delivery audit trail for all notifications',
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
      if (_stats.isNotEmpty) _buildStatsRow(),
      const SizedBox(height: 24),
      Row(children: [
        _buildFilter('Channel', _filterChannel, ['push', 'sms', 'email'], (v) { setState(() => _filterChannel = v); _loadData(); }),
        const SizedBox(width: 12),
        _buildFilter('Status', _filterStatus, ['sent', 'delivered', 'opened', 'failed'], (v) { setState(() => _filterStatus = v); _loadData(); }),
      ]).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      const SizedBox(height: 16),
      _isLoading ? const Center(child: CircularProgressIndicator()) : _buildLogsTable(),
    ]));
  }

  Widget _buildStatsRow() {
    return Wrap(spacing: 16, runSpacing: 16, children: [
      _statCard('Total', '${_stats['total'] ?? 0}', Icons.notifications, const Color(0xFF3B82F6)),
      _statCard('Delivered', '${_stats['delivered'] ?? 0}', Icons.check_circle, const Color(0xFF22C55E)),
      _statCard('Opened', '${_stats['opened'] ?? 0}', Icons.visibility, const Color(0xFF8B5CF6)),
      _statCard('Failed', '${_stats['failed'] ?? 0}', Icons.error, const Color(0xFFEF4444)),
      _statCard('Delivery Rate', '${(_stats['delivery_rate'] as num?)?.toStringAsFixed(1) ?? 0}%', Icons.speed, const Color(0xFF22C55E)),
      _statCard('Open Rate', '${(_stats['open_rate'] as num?)?.toStringAsFixed(1) ?? 0}%', Icons.trending_up, const Color(0xFF8B5CF6)),
    ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return AdvancedCard(
      width: 160,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  Widget _buildFilter(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
        value: value, hint: Text('All $label', style: TextStyle(color: Colors.white38, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B), style: TextStyle(color: Colors.white, fontSize: 13),
        items: [DropdownMenuItem(value: null, child: Text('All $label')), ...items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase())))],
        onChanged: onChanged)));
  }

  Widget _buildLogsTable() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: _logs.isEmpty
          ? const SizedBox(height: 300, child: Center(child: Text('No notification logs found.', style: TextStyle(color: Colors.white54))))
          : AdvancedTable(
              columns: const ['Title', 'User', 'Channel', 'Status', 'Sent At', 'Delivered', 'Opened', 'Error'],
              rows: _logs.map((l) {
                return [
                  Text(l.title, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                  Text(l.userId != null ? 'User #${l.userId}' : '—', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  StatusBadge(status: l.channel),
                  StatusBadge(status: l.status == 'delivered' ? 'Completed' : l.status == 'failed' ? 'Failed' : l.status == 'opened' ? 'Active' : 'Pending'),
                  Text(_formatTs(l.sentAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(l.deliveredAt != null ? '✓' : '—', style: TextStyle(color: l.deliveredAt != null ? const Color(0xFF22C55E) : Colors.white24)),
                  Text(l.openedAt != null ? '✓' : '—', style: TextStyle(color: l.openedAt != null ? const Color(0xFF8B5CF6) : Colors.white24)),
                  Text(l.errorMessage ?? '—', style: TextStyle(color: l.errorMessage != null ? const Color(0xFFEF4444) : Colors.white24, fontSize: 11), overflow: TextOverflow.ellipsis),
                ];
              }).toList(),
              onRowTap: (i) => _showLogDetails(_logs[i]),
            ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  String _formatTs(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }

  void _showLogDetails(NotificationLog l) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(40),
      child: Container(width: 600, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(24), child: Row(children: [
            Icon(l.channel == 'push' ? Icons.notification_important : l.channel == 'sms' ? Icons.sms : Icons.email, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Log Payload Inspector', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('ID: ${l.id} • ${l.channel.toUpperCase()}', style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white54)),
            ])),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
          ])),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _detailRow('Status', l.status.toUpperCase(), isPill: true, pillColor: l.status == 'delivered' ? const Color(0xFF22C55E) : l.status == 'failed' ? const Color(0xFFEF4444) : l.status == 'opened' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)),
            _detailRow('Recipient User ID', l.userId?.toString() ?? 'SYSTEM BROADCAST'),
            _detailRow('Message Title', l.title),
            _detailRow('Message Body / Template', l.message),
            const SizedBox(height: 16),
            Text('Timestamps', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _tsRow('Dispatched', l.sentAt),
                _tsRow('Delivered to Device', l.deliveredAt),
                _tsRow('User Opened/Read', l.openedAt),
              ])),
            if (l.errorMessage != null) ...[
              const SizedBox(height: 24),
              Text('Failure Reason', style: TextStyle(color: const Color(0xFFEF4444).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
                child: Text(l.errorMessage!, style: GoogleFonts.robotoMono(color: const Color(0xFFEF4444), fontSize: 12))),
            ],
            const SizedBox(height: 24),
            Text('Raw Metadata JSON', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Text('{\n  "payload": {\n    "routing": "${l.channel}",\n    "target_id": ${l.userId},\n    "priority": "high"\n  }\n}', style: GoogleFonts.robotoMono(color: const Color(0xFF22C55E), fontSize: 12))),
          ]))),
        ]),
      )
    ));
  }

  Widget _tsRow(String label, String? ts) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(color: Colors.white54, fontSize: 12))),
      Text(ts ?? 'Pending', style: GoogleFonts.robotoMono(color: ts == null ? const Color(0xFFF59E0B) : Colors.white, fontSize: 12)),
    ]));
  }

  Widget _detailRow(String label, String val, {bool isPill = false, Color pillColor = const Color(0xFF3B82F6)}) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 4),
      isPill ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: pillColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(val, style: TextStyle(color: pillColor, fontSize: 11, fontWeight: FontWeight.bold)))
             : Text(val, style: TextStyle(color: Colors.white, fontSize: 14)),
    ]));
  }
}
