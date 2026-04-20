import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/finance_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class InvoicesView extends StatefulWidget {
  const InvoicesView({super.key});
  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends SafeState<InvoicesView> {
  final FinanceRepository _repo = FinanceRepository();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _invoices = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _repo.getInvoiceStats();
    final data = await _repo.getInvoices(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
    setState(() { _stats = stats; _invoices = data['invoices'] ?? []; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Invoices', subtitle: 'View and manage all generated invoices.',
          actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),

        if (!_isLoading) ...[
          Row(children: [
            _stat('Total Invoices', '${_stats['total_invoices'] ?? 0}', Icons.receipt_outlined, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _stat('Total Amount', '₹${NumberFormat('#,##0').format(_stats['total_amount'] ?? 0)}', Icons.payments, const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            _stat('Tax Collected', '₹${NumberFormat('#,##0').format(_stats['total_tax_collected'] ?? 0)}', Icons.account_balance, const Color(0xFFF59E0B)),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Search
          SizedBox(height: 40, width: 320, child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _loadData(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by invoice number...', hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          )).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
        ],

        Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdvancedCard(padding: EdgeInsets.zero, child: AdvancedTable(
              columns: const ['Invoice #', 'User', 'Subtotal', 'Tax', 'Total', 'GSTIN', 'Late Fee', 'Date', ''],
              rows: _invoices.map((inv) {
                final date = DateTime.tryParse(inv['created_at'] ?? '') ?? DateTime.now();
                return [
                  Text(inv['invoice_number'] ?? '', style: GoogleFonts.firaCode(color: const Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(inv['user_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('₹${NumberFormat('#,##0.00').format(inv['subtotal'] ?? 0)}', style: const TextStyle(color: Colors.white70)),
                  Text('₹${NumberFormat('#,##0.00').format(inv['tax_amount'] ?? 0)}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
                  Text('₹${NumberFormat('#,##0.00').format(inv['total'] ?? 0)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(inv['gstin'] ?? 'N/A', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  inv['is_late_fee'] == true
                    ? Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('LATE FEE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold)))
                    : const SizedBox(),
                  Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  IconButton(icon: const Icon(Icons.open_in_new, color: Colors.white38, size: 16), onPressed: () => _showDetail(inv), tooltip: 'View Details'),
                ];
              }).toList(),
              onRowTap: (i) => _showDetail(_invoices[i]),
            )),
        ).animate().fadeIn(delay: 300.ms),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 11)),
      ])),
    ])),
  );

  void _showDetail(Map<String, dynamic> inv) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [const Icon(Icons.receipt, color: Color(0xFF3B82F6)), const SizedBox(width: 8),
        Text(inv['invoice_number'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))]),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('User', inv['user_name'] ?? ''),
        const Divider(color: Colors.white12),
        _row('Subtotal', '₹${NumberFormat('#,##0.00').format(inv['subtotal'] ?? 0)}'),
        _row('Tax (GST)', '₹${NumberFormat('#,##0.00').format(inv['tax_amount'] ?? 0)}'),
        _row('Total', '₹${NumberFormat('#,##0.00').format(inv['total'] ?? 0)}'),
        const Divider(color: Colors.white12),
        _row('GSTIN', inv['gstin'] ?? 'N/A'),
        _row('HSN Code', inv['hsn_code'] ?? 'N/A'),
        _row('Late Fee Invoice', inv['is_late_fee'] == true ? 'Yes' : 'No'),
        _row('Date', DateFormat('MMMM d, yyyy h:mm a').format(DateTime.tryParse(inv['created_at'] ?? '') ?? DateTime.now())),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white54)))],
    ));
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
    Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
  ]));
}
