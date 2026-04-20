import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/finance_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class SettlementsView extends StatefulWidget {
  const SettlementsView({super.key});
  @override
  State<SettlementsView> createState() => _SettlementsViewState();
}

class _SettlementsViewState extends SafeState<SettlementsView> {
  final FinanceRepository _repo = FinanceRepository();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _settlements = [];
  String? _statusFilter;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _repo.getSettlementStats();
    final data = await _repo.getSettlements(status: _statusFilter);
    setState(() { _stats = stats; _settlements = data['settlements'] ?? []; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Settlements', subtitle: 'Dealer and vendor settlement management.',
          actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),

        if (!_isLoading) ...[
          Row(children: [
            _stat('Total', '${_stats['total_settlements'] ?? 0}', Icons.description_outlined, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _stat('Pending', '${_stats['pending_count'] ?? 0}', Icons.hourglass_empty, const Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            _stat('Paid', '${_stats['paid_count'] ?? 0}', Icons.check_circle_outline, const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            _stat('Total Payable', '₹${NumberFormat('#,##0').format(_stats['total_payable'] ?? 0)}', Icons.payments_outlined, const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            _stat('Total Paid', '₹${NumberFormat('#,##0').format(_stats['total_paid'] ?? 0)}', Icons.account_balance_outlined, const Color(0xFF14B8A6)),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Status filter chips
          Row(children: [
            for (final f in [null, 'pending', 'generated', 'approved', 'paid'])
              Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
                selected: _statusFilter == f,
                label: Text(f?.toUpperCase() ?? 'ALL', style: TextStyle(color: _statusFilter == f ? Colors.white : Colors.white54, fontSize: 11)),
                selectedColor: const Color(0xFF3B82F6), backgroundColor: const Color(0xFF1E293B),
                onSelected: (_) { _statusFilter = f; _loadData(); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
              )),
          ]).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
        ],

        Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdvancedCard(padding: EdgeInsets.zero, child: AdvancedTable(
              columns: const ['ID', 'Dealer', 'Period', 'Revenue', 'Commission', 'Platform Fee', 'Net Payable', 'Status', 'Actions'],
              rows: _settlements.map((s) => [
                Text('#${s['id']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(s['dealer_name'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(s['settlement_month'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('₹${NumberFormat('#,##0').format(s['total_revenue'] ?? 0)}', style: GoogleFonts.outfit(color: Colors.white)),
                Text('₹${NumberFormat('#,##0').format(s['total_commission'] ?? 0)}', style: const TextStyle(color: Color(0xFF22C55E))),
                Text('₹${NumberFormat('#,##0').format(s['platform_fee'] ?? 0)}', style: const TextStyle(color: Colors.white54)),
                Text('₹${NumberFormat('#,##0').format(s['net_payable'] ?? 0)}', style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                StatusBadge(status: (s['status'] ?? '').toUpperCase()),
                s['status'] == 'pending' || s['status'] == 'generated'
                  ? IconButton(icon: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20), onPressed: () => _approve(s['id']), tooltip: 'Approve')
                  : const SizedBox(width: 24),
              ]).toList(),
              onRowTap: (i) => _showDetail(_settlements[i]),
            )),
        ).animate().fadeIn(delay: 300.ms),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(child: Row(children: [
      Icon(icon, color: color, size: 18), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ])),
    ])),
  );

  Future<void> _approve(int id) async {
    final ok = await _repo.approveSettlement(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Settlement approved' : 'Failed to approve'), backgroundColor: ok ? Colors.green : Colors.red));
      if (ok) _loadData();
    }
  }

  void _showDetail(Map<String, dynamic> s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [const Icon(Icons.description, color: Color(0xFF8B5CF6)), const SizedBox(width: 8),
        Text('Settlement #${s['id']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))]),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('Dealer', s['dealer_name'] ?? 'N/A'),
        _row('Period', s['settlement_month'] ?? ''),
        const Divider(color: Colors.white12),
        _row('Total Revenue', '₹${NumberFormat('#,##0.00').format(s['total_revenue'] ?? 0)}'),
        _row('Commission', '₹${NumberFormat('#,##0.00').format(s['total_commission'] ?? 0)}'),
        _row('Platform Fee', '₹${NumberFormat('#,##0.00').format(s['platform_fee'] ?? 0)}'),
        _row('Tax', '₹${NumberFormat('#,##0.00').format(s['tax_amount'] ?? 0)}'),
        const Divider(color: Colors.white12),
        _row('Net Payable', '₹${NumberFormat('#,##0.00').format(s['net_payable'] ?? 0)}'),
        _row('Status', (s['status'] ?? '').toUpperCase()),
        if (s['paid_at'] != null) _row('Paid On', DateFormat('MMMM d, yyyy').format(DateTime.tryParse(s['paid_at'] ?? '') ?? DateTime.now())),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white54)))],
    ));
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
    Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
  ]));
}
