import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/api_error_handler.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/logistics_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class DeliveryOrdersView extends StatefulWidget {
  const DeliveryOrdersView({super.key});
  @override
  State<DeliveryOrdersView> createState() => _DeliveryOrdersViewState();
}

class _DeliveryOrdersViewState extends SafeState<DeliveryOrdersView> {
  final LogisticsRepository _repo = LogisticsRepository();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<dynamic> _orders = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repo.getOrderStats(),
        _repo.getOrders(status: _statusFilter),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _stats = results[0];
        _orders = results[1]['orders'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
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
            title: 'Delivery Orders',
            subtitle:
                'Manage all delivery, restock, and reverse logistics orders.',
            actionButton: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadData,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          if (!_isLoading) ...[
            Row(
              children: [
                _stat(
                  'Total',
                  '${_stats['total_orders'] ?? 0}',
                  Icons.local_shipping_outlined,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _stat(
                  'Pending',
                  '${_stats['pending'] ?? 0}',
                  Icons.hourglass_empty,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _stat(
                  'In Transit',
                  '${_stats['in_transit'] ?? 0}',
                  Icons.delivery_dining,
                  const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 12),
                _stat(
                  'Delivered',
                  '${_stats['delivered'] ?? 0}',
                  Icons.check_circle_outline,
                  const Color(0xFF22C55E),
                ),
                const SizedBox(width: 12),
                _stat(
                  'Failed',
                  '${_stats['failed'] ?? 0}',
                  Icons.cancel_outlined,
                  const Color(0xFFEF4444),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            Row(
              children: [
                for (final f in [
                  null,
                  'pending',
                  'assigned',
                  'in_transit',
                  'delivered',
                  'failed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: _statusFilter == f,
                      label: Text(
                        (f ?? 'ALL').toUpperCase(),
                        style: TextStyle(
                          color: _statusFilter == f
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFF1E293B),
                      onSelected: (_) {
                        _statusFilter = f;
                        _loadData();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),
          ],

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : AdvancedCard(
                    padding: EdgeInsets.zero,
                    child: AdvancedTable(
                      columns: const [
                        'ID',
                        'Type',
                        'Driver',
                        'Origin',
                        'Destination',
                        'Status',
                        'OTP',
                        'Created',
                        'Actions',
                      ],
                      rows: _orders.map((o) {
                        final date =
                            DateTime.tryParse(o['created_at'] ?? '') ??
                            DateTime.now();
                        return [
                          Text(
                            '#${o['id']}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          _typeBadge(o['order_type'] ?? ''),
                          Text(
                            o['driver_name'] ?? 'Unassigned',
                            style: TextStyle(
                              color: o['driver_name'] == 'Unassigned'
                                  ? Colors.white38
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _addressChip(
                            o['origin_address'] ?? '',
                            Icons.trip_origin,
                          ),
                          _addressChip(
                            o['destination_address'] ?? '',
                            Icons.flag,
                          ),
                          StatusBadge(
                            status: _statusLabel(
                              (o['status'] ?? '').toString(),
                            ),
                          ),
                          o['otp_verified'] == true
                              ? const Icon(
                                  Icons.verified,
                                  color: Color(0xFF22C55E),
                                  size: 16,
                                )
                              : const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.white24,
                                  size: 16,
                                ),
                          Text(
                            DateFormat('MMM d').format(date),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white54,
                              size: 18,
                            ),
                            color: const Color(0xFF1E293B),
                            onSelected: (v) => _updateStatus(o['id'], v),
                            itemBuilder: (_) =>
                                [
                                      'pending',
                                      'assigned',
                                      'in_transit',
                                      'delivered',
                                      'failed',
                                      'cancelled',
                                    ]
                                    .map(
                                      (s) => PopupMenuItem(
                                        value: s,
                                        child: Text(
                                          _statusLabel(s),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ];
                      }).toList(),
                      onRowTap: (i) => _showDetail(_orders[i]),
                    ),
                  ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      return ApiErrorHandler.getReadableMessage(error);
    }
    return 'Unable to load delivery orders right now.';
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load delivery orders.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: AdvancedCard(
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _typeBadge(String type) {
    final colors = {
      'dealer_restock': const Color(0xFF3B82F6),
      'customer_delivery': const Color(0xFF22C55E),
      'reverse_logistics': const Color(0xFFF59E0B),
    };
    final c = colors[type] ?? const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _addressChip(String addr, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white38, size: 12),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          addr.length > 20 ? '${addr.substring(0, 20)}...' : addr,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Future<void> _updateStatus(int id, String status) async {
    final ok = await _repo.updateOrderStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Status updated to $status' : 'Failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) _loadData();
    }
  }

  void _showDetail(Map<String, dynamic> o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              'Order #${o['id']}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _row(
                'Type',
                (o['order_type'] ?? '')
                    .toString()
                    .replaceAll('_', ' ')
                    .toUpperCase(),
              ),
              _row('Status', _statusLabel((o['status'] ?? '').toString())),
              _row('Driver', o['driver_name'] ?? 'Unassigned'),
              const Divider(color: Colors.white12),
              _row('Origin', o['origin_address'] ?? ''),
              _row('Destination', o['destination_address'] ?? ''),
              if (o['scheduled_at'] != null)
                _row(
                  'Scheduled',
                  DateFormat('MMM d, h:mm a').format(
                    DateTime.tryParse(o['scheduled_at'] ?? '') ??
                        DateTime.now(),
                  ),
                ),
              if (o['started_at'] != null)
                _row(
                  'Started',
                  DateFormat('MMM d, h:mm a').format(
                    DateTime.tryParse(o['started_at'] ?? '') ?? DateTime.now(),
                  ),
                ),
              if (o['completed_at'] != null)
                _row(
                  'Completed',
                  DateFormat('MMM d, h:mm a').format(
                    DateTime.tryParse(o['completed_at'] ?? '') ??
                        DateTime.now(),
                  ),
                ),
              _row('OTP Verified', o['otp_verified'] == true ? 'Yes ✓' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            l,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  String _statusLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
