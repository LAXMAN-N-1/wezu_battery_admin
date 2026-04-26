import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/delivery_order_model.dart';
import '../data/repositories/logistics_repository.dart';

class DeliveryOrdersView extends ConsumerStatefulWidget {
  const DeliveryOrdersView({super.key});
  @override
  ConsumerState<DeliveryOrdersView> createState() => _DeliveryOrdersViewState();
}

class _DeliveryOrdersViewState extends ConsumerState<DeliveryOrdersView> {
  LogisticsRepository get _repo => ref.read(logisticsRepositoryProvider);
  bool _isOrdersLoading = true;
  bool _isStatsLoading = true;
  String? _ordersError;
  String? _statsError;
  Map<String, dynamic> _stats = {};
  List<DeliveryOrderModel> _orders = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadStats(), _loadOrders()]);
  }

  Future<void> _loadStats() async {
    setState(() {
      _isStatsLoading = true;
      _statsError = null;
    });
    try {
      final stats = await _repo.getOrderStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isStatsLoading = false);
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isOrdersLoading = true;
      _ordersError = null;
    });
    try {
      final ordersResponse = await _repo.getOrders(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        final rawList = ordersResponse['orders'] as List? ?? const [];
        _orders = rawList
            .map((json) => DeliveryOrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _ordersError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ordersError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isOrdersLoading = false);
      }
    }
  }

  void _showOrderDetails(DeliveryOrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AdvancedCard(
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailSection('Customer Information', [
                      _buildDetailRow('Name', order.customerName),
                      _buildDetailRow('Phone', order.customerPhone ?? 'Not provided'),
                    ]),
                    _buildDetailSection('Order Details', [
                      _buildDetailRow('Priority', order.priority.toUpperCase()),
                      _buildDetailRow('Units', '${order.units}'),
                      _buildDetailRow('Total Value', '\$${order.totalValue.toStringAsFixed(2)}'),
                      _buildDetailRow('Type', order.orderType.toUpperCase()),
                    ]),
                    _buildDetailSection('Logistics', [
                      _buildDetailRow('Status', order.status.toUpperCase()),
                      _buildDetailRow('Origin', order.originAddress),
                      _buildDetailRow('Destination', order.destinationAddress ?? 'Not provided'),
                      _buildDetailRow('Driver', order.driverName),
                      _buildDetailRow(
                        'Assigned Admin',
                        order.assignedAdminName ??
                            (order.assignedAdminId != null
                                ? 'Admin #${order.assignedAdminId}'
                                : 'Unassigned'),
                      ),
                      if (order.trackingNumber != null)
                        _buildDetailRow('Tracking', order.trackingNumber!),
                      if (order.assignedBatteryIds.isNotEmpty)
                        _buildDetailRow('Batteries', order.assignedBatteryIds.join(', ')),
                    ]),
                    if (order.proofOfDeliveryUrl != null || order.proofOfDeliveryNotes != null)
                      _buildDetailSection('Proof of Delivery', [
                        if (order.proofOfDeliveryNotes != null)
                          _buildDetailRow('Notes', order.proofOfDeliveryNotes!),
                        if (order.proofOfDeliveryUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Image',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {}, // Can add full screen image view here
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        order.proofOfDeliveryUrl!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.white10,
                                          child: const Icon(Icons.broken_image, color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
              onPressed: _refreshAll,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          if (!_isStatsLoading && _stats.isNotEmpty) ...[
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
          ] else if (_isStatsLoading) ...[
            const SizedBox(
              height: 88,
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),
          ],

          if (_statsError != null) ...[
            _buildInlineErrorCard(
              title: 'Order stats unavailable',
              message: _statsError!,
              onRetry: _loadStats,
            ),
            const SizedBox(height: 16),
          ],

          if (!_isOrdersLoading) ...[
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
                        _loadOrders();
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
            child: _isOrdersLoading
                ? const Center(child: CircularProgressIndicator())
                : _ordersError != null
                ? _buildInlineErrorCard(
                    title: 'Orders failed to load',
                    message: _ordersError!,
                    onRetry: _loadOrders,
                  )
                : _orders.isEmpty
                ? AdvancedCard(
                    child: Center(
                      child: Text(
                        'No orders found for the selected filter.',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
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
                      onRowTap: (index) {
                        _showOrderDetails(_orders[index]);
                      },
                      rows: _orders.map((o) {
                        final date = o.createdAt ?? DateTime.now();
                        return [
                          Text(
                            '#${o.id}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          _typeBadge(o.orderType),
                          Text(
                            o.driverName,
                            style: TextStyle(
                              color: o.driverName == 'Unassigned'
                                  ? Colors.white38
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _addressChip(
                            o.originAddress,
                            Icons.trip_origin,
                          ),
                          _addressChip(
                            o.destinationAddress ?? 'Not specified',
                            Icons.flag,
                          ),
                          StatusBadge(
                            status: o.status.toUpperCase(),
                          ),
                          o.otpVerified
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
                            onSelected: (v) => _updateStatus(o.id, v),
                            itemBuilder: (_) =>
                                [
                                      'pending',
                                      'assigned',
                                      'in_transit',
                                      'delivered',
                                      'failed',
                                      'cancelled',
                                    ].map((s) {
                                  return PopupMenuItem<String>(
                                    value: s,
                                    child: Text(
                                      s.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ];
                      }).toList(),
                    ),
                  ),
          ).animate().fadeIn(delay: 300.ms),
        ],
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

  Future<void> _updateStatus(Object id, String status) async {
    final ok = await _repo.updateOrderStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Status updated to $status' : 'Failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) {
        _loadOrders();
        _loadStats();
      }
    }
  }

  Widget _buildInlineErrorCard({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
