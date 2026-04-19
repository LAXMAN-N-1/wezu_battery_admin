import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/late_fee_model.dart';
import '../data/repositories/rental_repository.dart';

class LateFeesView extends StatefulWidget {
  const LateFeesView({super.key});

  @override
  State<LateFeesView> createState() => _LateFeesViewState();
}

class _LateFeesViewState extends State<LateFeesView> {
  final RentalRepository _repository = RentalRepository();
  List<LateFee> _lateFees = [];
  bool _isLoading = true;
  String _paymentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final fees = await _repository.getLateFees();
    setState(() { _lateFees = fees; _isLoading = false; });
  }

  List<LateFee> get _filtered => _paymentFilter == 'all'
      ? _lateFees
      : _lateFees.where((l) => l.paymentStatus.toLowerCase() == _paymentFilter.toLowerCase()).toList();

  @override
  Widget build(BuildContext context) {
    final totalFees = _lateFees.fold<double>(0, (s, l) => s + l.totalLateFee);
    final pendingWaivers = _lateFees.where((l) => l.waiverStatus == 'PENDING').length;
    final avgDaysLate = _lateFees.isNotEmpty ? _lateFees.fold<int>(0, (s, l) => s + l.daysOverdue) ~/ _lateFees.length : 0;
    final unpaid = _lateFees.where((l) => l.paymentStatus.toLowerCase() == 'unpaid').length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Late Fees & Waivers',
            subtitle: 'Manage overdue rentals, penalty calculations, and waiver requests.',
            actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _buildStat('Total Fees', '₹${NumberFormat('#,##0').format(totalFees)}', Icons.money_off_outlined, const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              _buildStat('Unpaid', '$unpaid', Icons.warning_amber_outlined, const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _buildStat('Pending Waivers', '$pendingWaivers', Icons.pending_outlined, const Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              _buildStat('Avg Days Late', '$avgDaysLate days', Icons.schedule_outlined, const Color(0xFF3B82F6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 20),

          // Filters
          Row(
            children: ['all', 'unpaid', 'paid', 'waived'].map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _paymentFilter == s,
                label: Text(s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1), style: TextStyle(color: _paymentFilter == s ? Colors.white : Colors.white54, fontSize: 12)),
                selectedColor: const Color(0xFF3B82F6), backgroundColor: const Color(0xFF1E293B),
                checkmarkColor: Colors.white,
                onSelected: (_) => setState(() => _paymentFilter = s),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.transparent)),
              ),
            )).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 20),

          Expanded(
            child: AdvancedCard(
              padding: EdgeInsets.zero,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                  ? const Center(child: Text('No late fees found.', style: TextStyle(color: Colors.white54)))
                  : AdvancedTable(
                      columns: const ['ID', 'User', 'Rental', 'Days Late', 'Fee', 'Payment', 'Waiver', 'Actions'],
                      rows: _filtered.map((lf) => [
                        Text('#LF${lf.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(lf.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('#${lf.rentalId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (lf.daysOverdue > 5 ? const Color(0xFFEF4444) : lf.daysOverdue > 3 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${lf.daysOverdue} days',
                            style: TextStyle(
                              color: lf.daysOverdue > 5 ? const Color(0xFFEF4444) : lf.daysOverdue > 3 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                              fontSize: 11, fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('₹${lf.totalLateFee.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                        StatusBadge(status: lf.paymentStatus),
                        _buildWaiverBadge(lf.waiverStatus),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          if (lf.waiverStatus == 'PENDING' && lf.waiverId != null)
                            IconButton(
                              icon: const Icon(Icons.fact_check_outlined, color: Color(0xFFF59E0B), size: 18),
                              tooltip: 'Review Waiver',
                              onPressed: () => _reviewWaiver(lf),
                            ),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, color: Colors.white54, size: 18),
                            tooltip: 'View Details',
                            onPressed: () => _showDetail(lf),
                          ),
                        ]),
                      ]).toList(),
                    ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildWaiverBadge(String status) {
    if (status == 'NONE') return const Text('—', style: TextStyle(color: Colors.white24));
    final color = status == 'PENDING' ? const Color(0xFFF59E0B)
        : status == 'APPROVED' ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showDetail(LateFee lf) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.money_off, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Late Fee #LF${lf.id}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(lf.userName, style: const TextStyle(color: Colors.white54)),
                ])),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ]),
              const Divider(color: Colors.white12, height: 32),
              _detailInfoRow('Rental', '#${lf.rentalId}'),
              _detailInfoRow('Days Overdue', '${lf.daysOverdue} days'),
              _detailInfoRow('Daily Rate', '₹${lf.dailyRate.toStringAsFixed(2)}'),
              _detailInfoRow('Base Fee', '₹${lf.baseFee.toStringAsFixed(2)}'),
              _detailInfoRow('Total Fee', '₹${lf.totalLateFee.toStringAsFixed(2)}'),
              _detailInfoRow('Payment', lf.paymentStatus),
              _detailInfoRow('Waiver', lf.waiverStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

  void _reviewWaiver(LateFee lf) {
    final amountCtrl = TextEditingController(text: lf.totalLateFee.toStringAsFixed(2));
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Waiver Request', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('${lf.userName} • ${lf.daysOverdue} days overdue • ₹${lf.totalLateFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              Text('Approved Waiver Amount', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1E293B), prefixText: '₹ ', prefixStyle: const TextStyle(color: Colors.white54), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              Text('Admin Notes', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1E293B), hintText: 'Optional justification...', hintStyle: const TextStyle(color: Colors.white24), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final ok = await _repository.reviewWaiver(lf.waiverId!, 'REJECTED', notes: notesCtrl.text);
                    if (ok) { nav.pop(); _loadData(); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final ok = await _repository.reviewWaiver(
                      lf.waiverId!, 'APPROVED',
                      approvedAmount: double.tryParse(amountCtrl.text),
                      notes: notesCtrl.text,
                    );
                    if (ok) { nav.pop(); _loadData(); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Approve'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}
