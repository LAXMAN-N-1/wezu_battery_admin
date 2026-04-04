import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/finance_repository.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});
  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final FinanceRepository _repo = FinanceRepository();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _transactions = [];
  String? _statusFilter, _typeFilter;

  final _types = ['RENTAL_PAYMENT','SECURITY_DEPOSIT','WALLET_TOPUP','REFUND','FINE','SUBSCRIPTION','PURCHASE','SWAP_FEE','LATE_FEE','CASHBACK'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _repo.getTransactionStats();
    final data = await _repo.getTransactions(type: _typeFilter, status: _statusFilter);
    setState(() { _stats = stats; _transactions = data['transactions'] ?? []; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Transactions', subtitle: 'View and manage all financial transactions.',
          actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),

        if (!_isLoading) ...[
          // Stats
          Row(children: [
            _stat('Total', '${_stats['total_transactions'] ?? 0}', Icons.receipt_long, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _stat('Success', '${_stats['success_count'] ?? 0}', Icons.check_circle, const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            _stat('Pending', '${_stats['pending_count'] ?? 0}', Icons.schedule, const Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            _stat('Failed', '${_stats['failed_count'] ?? 0}', Icons.cancel, const Color(0xFFEF4444)),
            const SizedBox(width: 12),
            _stat('Total Volume', '₹${NumberFormat('#,##0').format(_stats['total_amount'] ?? 0)}', Icons.account_balance_wallet, const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            _stat("Today's Volume", '₹${NumberFormat('#,##0').format(_stats['today_amount'] ?? 0)}', Icons.today, const Color(0xFF14B8A6)),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Filters
          Row(children: [
            _filterChip('All', null, _statusFilter, (v) => setState(() { _statusFilter = v; _loadData(); })),
            _filterChip('Success', 'success', _statusFilter, (v) => setState(() { _statusFilter = v; _loadData(); })),
            _filterChip('Pending', 'pending', _statusFilter, (v) => setState(() { _statusFilter = v; _loadData(); })),
            _filterChip('Failed', 'failed', _statusFilter, (v) => setState(() { _statusFilter = v; _loadData(); })),
            const SizedBox(width: 16),
            Expanded(child: SizedBox(
              height: 36,
              child: DropdownButtonFormField<String>(
                initialValue: _typeFilter,
                hint: const Text('Filter by type', style: TextStyle(color: Colors.white38, fontSize: 12)),
                dropdownColor: const Color(0xFF1E293B),
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: [const DropdownMenuItem<String>(value: null, child: Text('All Types')), ..._types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))],
                onChanged: (v) { _typeFilter = v; _loadData(); },
              ),
            )),
          ]).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
        ],

        // Table
        Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdvancedCard(padding: EdgeInsets.zero, child: AdvancedTable(
              columns: const ['ID', 'User', 'Type', 'Amount', 'Tax', 'Method', 'Status', 'Date'],
              rows: _transactions.map((tx) {
                final createdAt = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                return [
                  Text('#${tx['id']}', style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
                  Text(tx['user_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  _typeBadge(tx['transaction_type'] ?? ''),
                  Text('₹${NumberFormat('#,##0.00').format(tx['amount'] ?? 0)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('₹${NumberFormat('#,##0').format(tx['tax_amount'] ?? 0)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  _methodIcon(tx['payment_method'] ?? ''),
                  StatusBadge(status: (tx['status'] ?? '').toString().toUpperCase()),
                  Text(DateFormat('MMM d, h:mm a').format(createdAt), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ];
              }).toList(),
              onRowTap: (i) => _showDetail(_transactions[i]),
            )),
        ).animate().fadeIn(delay: 300.ms),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ])),
    ])),
  );

  Widget _filterChip(String label, String? value, String? currentFilter, void Function(String?) onTap) {
    final selected = currentFilter == value;
    return Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
      selected: selected, label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 11)),
      selectedColor: const Color(0xFF3B82F6), backgroundColor: const Color(0xFF1E293B),
      onSelected: (_) => onTap(value), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
    ));
  }

  Widget _typeBadge(String type) {
    final colors = {'RENTAL_PAYMENT': const Color(0xFF3B82F6), 'SUBSCRIPTION': const Color(0xFF8B5CF6), 'PURCHASE': const Color(0xFF22C55E), 'REFUND': const Color(0xFFEF4444), 'SWAP_FEE': const Color(0xFF14B8A6)};
    final c = colors[type.toUpperCase()] ?? const Color(0xFFF59E0B);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(type.replaceAll('_', ' '), style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
  }

  Widget _methodIcon(String method) {
    final icons = {'upi': Icons.phone_android, 'card': Icons.credit_card, 'netbanking': Icons.account_balance, 'wallet': Icons.account_balance_wallet};
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icons[method] ?? Icons.payment, color: Colors.white54, size: 14),
      const SizedBox(width: 4),
      Text(method.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]);
  }

  void _showDetail(Map<String, dynamic> tx) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.receipt_long, color: Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text('Transaction #${tx['id']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _detailRow('User', tx['user_name'] ?? ''),
        _detailRow('Type', (tx['transaction_type'] ?? '').toString().replaceAll('_', ' ')),
        _detailRow('Amount', '₹${NumberFormat('#,##0.00').format(tx['amount'] ?? 0)}'),
        _detailRow('Tax', '₹${NumberFormat('#,##0.00').format(tx['tax_amount'] ?? 0)}'),
        _detailRow('Payment Method', (tx['payment_method'] ?? '').toUpperCase()),
        _detailRow('Gateway Ref', tx['payment_gateway_ref'] ?? 'N/A'),
        _detailRow('Status', (tx['status'] ?? '').toUpperCase()),
        _detailRow('Description', tx['description'] ?? 'N/A'),
        _detailRow('Date', DateFormat('MMMM d, yyyy h:mm a').format(DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white54))),
      ],
    ));
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
    ]),
  );
}
