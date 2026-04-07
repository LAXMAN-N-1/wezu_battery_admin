import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/logistics_repository.dart';

class ReturnsView extends StatefulWidget {
  const ReturnsView({super.key});
  @override
  State<ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<ReturnsView> {
  final LogisticsRepository _repo = LogisticsRepository();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _returns = [];
  String? _statusFilter;

  final _pipeline = ['pending', 'pickup_assigned', 'in_transit', 'received', 'inspected', 'completed'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repo.getReturnStats(),
      _repo.getReturns(status: _statusFilter),
    ]);
    setState(() { _stats = results[0] as Map<String, dynamic>; _returns = results[1] as List<dynamic>; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Returns', subtitle: 'Process return requests, inspections, and refunds.',
        actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 16),

      if (!_isLoading) ...[
        Row(children: [
          _stat('Total Returns', '${_stats['total_returns'] ?? 0}', Icons.assignment_return_outlined, const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          _stat('Pending', '${_stats['pending'] ?? 0}', Icons.hourglass_empty, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _stat('Completed', '${_stats['completed'] ?? 0}', Icons.check_circle_outline, const Color(0xFF22C55E)),
          const SizedBox(width: 12),
          _stat('Total Refunds', '₹${NumberFormat('#,##0').format(_stats['total_refund_amount'] ?? 0)}', Icons.payments_outlined, const Color(0xFF8B5CF6)),
        ]).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),

        Row(children: [
          for (final f in [null, ..._pipeline, 'cancelled'])
            Padding(padding: const EdgeInsets.only(right: 4), child: FilterChip(
              selected: _statusFilter == f,
              label: Text((f ?? 'ALL').replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _statusFilter == f ? Colors.white : Colors.white54, fontSize: 9)),
              selectedColor: const Color(0xFF3B82F6), backgroundColor: const Color(0xFF1E293B),
              onSelected: (_) { _statusFilter = f; _loadData(); },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )),
        ]).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 16),
      ],

      Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _returns.isEmpty
          ? Center(child: Text('No return requests', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)))
          : AdvancedCard(padding: EdgeInsets.zero, child: AdvancedTable(
              columns: const ['ID', 'User', 'Reason', 'Status', 'Refund', 'Notes', 'Date', 'Actions'],
              rows: _returns.map((r) {
                final date = DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now();
                return [
                  Text('#${r['id']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(r['user_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Flexible(child: Text(r['reason'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  _statusPipeline(r['status'] ?? 'pending'),
                  Text(r['refund_amount'] != null ? '₹${NumberFormat('#,##0').format(r['refund_amount'])}' : '—', style: TextStyle(color: r['refund_amount'] != null ? const Color(0xFF22C55E) : Colors.white30, fontWeight: FontWeight.bold)),
                  Text(r['inspection_notes'] ?? '—', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(DateFormat('MMM d').format(date), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                    color: const Color(0xFF1E293B),
                    onSelected: (v) => _updateStatus(r['id'], v),
                    itemBuilder: (_) => [..._pipeline, 'cancelled']
                      .map((s) => PopupMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)))).toList(),
                  ),
                ];
              }).toList(),
              onRowTap: (i) => _showDetail(_returns[i]),
            )),
      ).animate().fadeIn(delay: 300.ms),
    ]));
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Expanded(child: AdvancedCard(child: Row(children: [
    Icon(icon, color: color, size: 18), const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ])),
  ])));

  Widget _statusPipeline(String status) {
    final idx = _pipeline.indexOf(status);
    final isCancelled = status == 'cancelled';
    if (isCancelled) return StatusBadge(status: 'CANCELLED');

    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(_pipeline.length, (i) {
      final isActive = i <= idx;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(
          color: isActive ? const Color(0xFF22C55E) : Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle,
          border: Border.all(color: isActive ? const Color(0xFF22C55E) : Colors.white24, width: 1),
        )),
        if (i < _pipeline.length - 1) Container(width: 8, height: 1, color: isActive ? const Color(0xFF22C55E).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
      ]);
    }));
  }

  Future<void> _updateStatus(int id, String status) async {
    final ok = await _repo.updateReturnStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Updated to $status' : 'Failed'), backgroundColor: ok ? Colors.green : Colors.red));
      if (ok) _loadData();
    }
  }

  void _showDetail(Map<String, dynamic> r) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [const Icon(Icons.assignment_return, color: Color(0xFFF59E0B)), const SizedBox(width: 8),
        Text('Return #${r['id']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))]),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('User', r['user_name'] ?? ''),
        _row('Order ID', '#${r['order_id']}'),
        _row('Reason', r['reason'] ?? ''),
        _row('Status', (r['status'] ?? '').replaceAll('_', ' ').toUpperCase()),
        _row('Refund Amount', r['refund_amount'] != null ? '₹${NumberFormat('#,##0.00').format(r['refund_amount'])}' : 'Not set'),
        _row('Inspection Notes', r['inspection_notes'] ?? 'None'),
        _row('Date', DateFormat('MMMM d, yyyy').format(DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now())),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white54)))],
    ));
  }

  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    SizedBox(width: 120, child: Text(l, style: const TextStyle(color: Colors.white38, fontSize: 12))),
    Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
  ]));
}
