import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/purchase_model.dart';
import '../data/repositories/rental_repository.dart';

class PurchaseOrdersView extends StatefulWidget {
  const PurchaseOrdersView({super.key});

  @override
  State<PurchaseOrdersView> createState() => _PurchaseOrdersViewState();
}

class _PurchaseOrdersViewState extends State<PurchaseOrdersView> {
  final RentalRepository _repository = RentalRepository();
  List<PurchaseOrder> _purchases = [];
  bool _isLoading = true;
  PurchaseOrder? _selectedPurchase;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final purchases = await _repository.getPurchases();
    setState(() { _purchases = purchases; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _purchases.fold<double>(0, (s, p) => s + p.amount);
    final avgOrderValue = _purchases.isNotEmpty ? totalRevenue / _purchases.length : 0.0;

    return Row(
      children: [
        Expanded(
          flex: _selectedPurchase != null ? 3 : 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Purchase Orders',
                  subtitle: 'Direct battery sales and purchase transactions.',
                  actionButton: Row(children: [
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ]),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Stats
                Row(
                  children: [
                    _buildStat('Total Orders', '${_purchases.length}', Icons.shopping_cart_outlined, const Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    _buildStat('Total Revenue', '₹${NumberFormat('#,##0').format(totalRevenue)}', Icons.payments_outlined, const Color(0xFF22C55E)),
                    const SizedBox(width: 12),
                    _buildStat('Avg Order', '₹${NumberFormat('#,##0').format(avgOrderValue)}', Icons.analytics_outlined, const Color(0xFF8B5CF6)),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 20),

                Expanded(
                  child: AdvancedCard(
                    padding: EdgeInsets.zero,
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _purchases.isEmpty
                        ? const Center(child: Text('No purchase orders found.', style: TextStyle(color: Colors.white54)))
                        : AdvancedTable(
                            columns: const ['Order', 'Customer', 'Battery', 'Amount', 'Date'],
                            rows: _purchases.map((p) => [
                              Text('#PO${p.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(p.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text('BAT_${p.batteryId}', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              Text('₹${NumberFormat('#,##0.00').format(p.amount)}', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                              Text(DateFormat('MMM dd, yyyy').format(p.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ]).toList(),
                            onRowTap: (i) => setState(() => _selectedPurchase = _purchases[i]),
                          ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              ],
            ),
          ),
        ),
        if (_selectedPurchase != null)
          Container(
            width: 340,
            decoration: const BoxDecoration(color: Color(0xFF0F172A), border: Border(left: BorderSide(color: Colors.white12))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Order #PO${_selectedPurchase!.id}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => setState(() => _selectedPurchase = null)),
                  ]),
                  const SizedBox(height: 4),
                  const StatusBadge(status: 'Completed'),
                  const Divider(color: Colors.white12, height: 32),
                  _infoRow('Customer', _selectedPurchase!.userName),
                  _infoRow('Battery', 'BAT_${_selectedPurchase!.batteryId}'),
                  _infoRow('Amount', '₹${NumberFormat('#,##0.00').format(_selectedPurchase!.amount)}'),
                  _infoRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(_selectedPurchase!.timestamp)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color(0xFF22C55E).withValues(alpha: 0.08), const Color(0xFF3B82F6).withValues(alpha: 0.08)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 32),
                        SizedBox(height: 8),
                        Text('Payment Received', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

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
