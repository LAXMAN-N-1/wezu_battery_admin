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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final purchases = await _repository.getPurchases();
    setState(() {
      _purchases = purchases;
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
                  Text('Purchase Orders', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Direct battery sales and purchase transactions from users.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Expanded(
            child: AdvancedCard(
              padding: EdgeInsets.zero,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _purchases.isEmpty
                    ? const Center(child: Text('No purchase orders found.', style: TextStyle(color: Colors.white54)))
                    : AdvancedTable(
                        columns: const ['Order ID', 'Customer', 'Battery ID', 'Amount Paid', 'Status', 'Date'],
                        rows: _purchases.map((p) {
                          return [
                            Text('#PO${p.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(p.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('BAT_${p.batteryId}', style: const TextStyle(color: Colors.white70)),
                            Text('₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                            const StatusBadge(status: 'Completed'),
                            Text(DateFormat('MMM dd, yyyy').format(p.timestamp), style: const TextStyle(color: Colors.white54)),
                          ];
                        }).toList(),
                      ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }
}
