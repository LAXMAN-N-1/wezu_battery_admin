import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/audit_models.dart';
import '../data/repositories/audit_repository.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});
  @override State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  final AuditRepository _repo = AuditRepository();
  List<AuditLogItem> _logs = [];
  List<String> _availableActions = [];
  bool _isLoading = true;
  String? _filterAction;
  int _skip = 0;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_availableActions.isEmpty) {
        final stats = await _repo.getAuditStats();
        final Map<String, dynamic> byAction = stats['by_action'] ?? {};
        if (byAction.isNotEmpty) {
          _availableActions = byAction.keys.toList()..sort();
        }
      }

      final res = await _repo.getAuditLogs(action: _filterAction, skip: _skip);
      setState(() {
        _logs = res['items'] as List<AuditLogItem>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/settings/health'),
            icon: const Icon(Icons.arrow_back, size: 16, color: Colors.blue),
            label: Text(
              'Back to System Health',
              style: GoogleFonts.inter(
                color: Colors.blue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'System Audit Logs',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track and monitor all administrative actions',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildFilter(
                'Action',
                _filterAction,
                _availableActions.isNotEmpty
                    ? _availableActions
                    : ['login', 'create', 'update', 'delete', 'suspend', 'resolve'],
                (v) {
                  setState(() {
                    _filterAction = v;
                    _skip = 0;
                  });
                  _loadData();
                },
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          focusColor: Colors.transparent,
          hint: Text('All $label', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          dropdownColor: const Color(0xFF1E293B),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 20),
          items: [
            DropdownMenuItem(value: null, child: Text('All $label')),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase()))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLogsTable() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.03)),
        columns: const [
          DataColumn(label: Text('Timestamp', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('User ID', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Action', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Resource Type', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Resource ID', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Details', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('IP / User Agent', style: TextStyle(color: Colors.white70))),
        ],
        rows: _logs.map((l) {
          final actionColor = l.action == 'create' ? Colors.green : l.action == 'delete' ? Colors.red : l.action == 'update' ? Colors.blue : Colors.orange;
          return DataRow(cells: [
            DataCell(Text(_formatTs(l.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12))),
            DataCell(Text(l.userId?.toString() ?? 'System', style: const TextStyle(color: Colors.white, fontSize: 13))),
            DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(l.action.toUpperCase(), style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold)))),
            DataCell(Text(l.resourceType.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12))),
            DataCell(Text(l.resourceId ?? '—', style: const TextStyle(color: Colors.white, fontSize: 13))),
            DataCell(SizedBox(width: 250, child: Text(l.details, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2))),
            DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.ipAddress ?? '—', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
              SizedBox(width: 150, child: Text(l.userAgent ?? '—', style: const TextStyle(color: Colors.white38, fontSize: 10), overflow: TextOverflow.ellipsis)),
            ])),
          ]);
        }).toList(),
      )),
    );
  }

  String _formatTs(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }
}
