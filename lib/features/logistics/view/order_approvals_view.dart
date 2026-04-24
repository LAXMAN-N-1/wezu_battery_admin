import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/logistics_repository.dart';

class OrderApprovalsView extends StatefulWidget {
  const OrderApprovalsView({super.key});

  @override
  State<OrderApprovalsView> createState() => _OrderApprovalsViewState();
}

class _OrderApprovalsViewState extends State<OrderApprovalsView> {
  final LogisticsRepository _repo = LogisticsRepository();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _repo.getPendingApprovals();
      if (!mounted) return;
      setState(() {
        _orders = response['orders'] as List? ?? const [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleApprove(String orderId) async {
    final notesCtrl = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Approve Order #$orderId',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will approve the order and assign it to the default warehouse based on the dealer\'s region.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Approval Notes (Optional)',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.approveOrder(orderId, notes: notesCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order approved successfully'), backgroundColor: Colors.green),
          );
          _loadApprovals();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleReject(String orderId) async {
    final reasonCtrl = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Reject Order #$orderId',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to reject this order?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Reason for Rejection *',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Reason is required'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.rejectOrder(orderId, reasonCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order rejected'), backgroundColor: Colors.green),
          );
          _loadApprovals();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Order Approvals',
            subtitle: 'Review and approve pending warehouse delivery orders.',
            actionButton: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadApprovals,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _orders.isEmpty
                        ? _buildEmptyState()
                        : _buildTable(),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return AdvancedCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Failed to load approvals',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadApprovals,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AdvancedCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF22C55E)),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'There are no orders pending your approval.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const [
          'Order ID',
          'Dealer',
          'Units',
          'Destination',
          'Created',
          'Actions',
        ],
        rows: _orders.map((o) {
          final date = DateTime.tryParse(o['order_date'] ?? o['created_at'] ?? '') ?? DateTime.now();
          final id = o['id'].toString();
          return [
            Text(
              id,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              o['dealer_id'] != null ? "Dealer ID: ${o['dealer_id']}" : 'Unknown Dealer',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${o['units'] ?? 0} Batteries",
                style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              o['destination'] ?? 'N/A',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              DateFormat('MMM d, h:mm a').format(date),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                  tooltip: 'Approve Order',
                  onPressed: () => _handleApprove(id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Reject Order',
                  onPressed: () => _handleReject(id),
                ),
              ],
            ),
          ];
        }).toList(),
      ),
    );
  }
}
