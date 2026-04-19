import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/audit_models.dart';
import '../data/repositories/audit_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});
  @override State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  final AuditRepository _repo = AuditRepository();
  List<AuditLogItem> _logs = [];
  bool _isLoading = true;
  String? _filterAction;
  int _skip = 0;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getAuditLogs(action: _filterAction, skip: _skip);
      setState(() { _logs = res['items'] as List<AuditLogItem>; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: 'System Audit Logs',
        subtitle: 'Track and monitor all administrative actions',
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
      Row(children: [
        _buildFilter('Action', _filterAction, ['login', 'create', 'update', 'delete', 'suspend', 'resolve'], (v) {
          setState(() { _filterAction = v; _skip = 0; }); _loadData();
        }),
      ]).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      const SizedBox(height: 16),
      _isLoading ? const Center(child: CircularProgressIndicator()) : _buildLogsTable(),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (_skip > 0)
          TextButton(onPressed: () { setState(() => _skip = (_skip - 50 > 0 ? _skip - 50 : 0)); _loadData(); }, child: const Text('Previous')),
        if (_logs.length == 50)
          TextButton(onPressed: () { setState(() => _skip += 50); _loadData(); }, child: const Text('Next')),
      ]),
    ]));
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
          ? const SizedBox(height: 300, child: Center(child: Text('No audit logs found.', style: TextStyle(color: Colors.white54))))
          : AdvancedTable(
              columns: const ['Timestamp', 'User ID', 'Action', 'Resource Type', 'Resource ID', 'Details', 'IP / User Agent'],
              rows: _logs.map((l) {
                final actionColor = l.action == 'create' ? const Color(0xFF22C55E) : l.action == 'delete' ? const Color(0xFFEF4444) : l.action == 'update' ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);
                return [
                  Text(_formatTs(l.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(l.userId?.toString() ?? 'System', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  StatusBadge(status: l.action),
                  Text(l.resourceType.toUpperCase(), style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
                  Text(l.resourceId ?? '—', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  Text(l.details, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.ipAddress ?? '—', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11)),
                    Text(l.userAgent ?? '—', style: const TextStyle(color: Colors.white38, fontSize: 10), overflow: TextOverflow.ellipsis),
                  ]),
                ];
              }).toList(),
            ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  String _formatTs(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }
}
