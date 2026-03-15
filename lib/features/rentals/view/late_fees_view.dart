import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final fees = await _repository.getLateFees();
    setState(() {
      _lateFees = fees;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Late Fees & Waivers', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Manage overdue rentals, penalty calculations, and waiver requests.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _loadData,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Expanded(
            child: AdvancedCard(
              padding: EdgeInsets.zero,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lateFees.isEmpty
                    ? const Center(child: Text('No late fees recorded.', style: TextStyle(color: Colors.white54)))
                    : AdvancedTable(
                        columns: const ['Fee ID', 'User', 'Days Late', 'Total Fee', 'Payment Status', 'Waiver', 'Actions'],
                        rows: _lateFees.map((lf) {
                          return [
                            Text('#LF${lf.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(lf.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${lf.daysOverdue} Days', style: TextStyle(color: lf.daysOverdue > 3 ? const Color(0xFFEF4444) : Colors.white70)),
                            Text('₹${lf.totalLateFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            StatusBadge(status: lf.paymentStatus),
                            _buildWaiverBadge(lf.waiverStatus),
                            Row(
                              children: [
                                if (lf.waiverStatus == 'PENDING' && lf.waiverId != null)
                                  IconButton(icon: const Icon(Icons.fact_check_outlined, color: Color(0xFFF59E0B), size: 20), onPressed: () => _reviewWaiver(lf)),
                                IconButton(icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3B82F6), size: 20), onPressed: () {}),
                              ],
                            ),
                          ];
                        }).toList(),
                      ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildWaiverBadge(String status) {
    if (status == 'NONE') return const Text('—', style: TextStyle(color: Colors.white24));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status == 'PENDING' ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status, style: TextStyle(color: status == 'PENDING' ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _reviewWaiver(LateFee lf) {
    // Dialog to approve/reject waiver
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Review Waiver #${lf.waiverId}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${lf.userName}', style: const TextStyle(color: Colors.white70)),
            Text('Days Late: ${lf.daysOverdue}', style: const TextStyle(color: Colors.white70)),
            Text('Total Fee: ₹${lf.totalLateFee}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Approved Waiver Amount',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final ok = await _repository.reviewWaiver(lf.waiverId!, 'REJECTED');
              if (ok) {
                navigator.pop();
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final ok = await _repository.reviewWaiver(lf.waiverId!, 'APPROVED', approvedAmount: lf.totalLateFee);
              if (ok) {
                navigator.pop();
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            child: const Text('Approve Full'),
          ),
        ],
      ),
    );
  }
}
