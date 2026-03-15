import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/commission.dart';
import '../data/repositories/dealer_repository.dart';

class DealerCommissionsView extends StatefulWidget {
  const DealerCommissionsView({super.key});

  @override
  State<DealerCommissionsView> createState() => _DealerCommissionsViewState();
}

class _DealerCommissionsViewState extends State<DealerCommissionsView> {
  final DealerRepository _repository = DealerRepository();
  List<CommissionConfig> _configs = [];
  List<CommissionLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getCommissionConfigs(),
      _repository.getCommissionLogs(),
    ]);
    setState(() {
      _configs = results[0] as List<CommissionConfig>;
      _logs = results[1] as List<CommissionLog>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  Text('Commissions', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Configure dealer commission rates and track all-time earnings log.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Configs Table
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Configurations', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    AdvancedCard(
                      padding: EdgeInsets.zero,
                      child: _isLoading 
                        ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                        : AdvancedTable(
                            columns: const ['Transaction Type', 'Percentage (%)', 'Flat Fee (₹)', 'Status', 'Actions'],
                            rows: _configs.map((c) {
                              return [
                                Text(c.transactionType.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('${c.percentage}%', style: const TextStyle(color: Colors.white)),
                                Text('₹${c.flatFee}', style: const TextStyle(color: Colors.white)),
                                StatusBadge(status: c.isActive ? 'Active' : 'Inactive'),
                                IconButton(icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18), onPressed: () {}),
                              ];
                            }).toList(),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Logs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Earnings', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    AdvancedCard(
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _logs.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(log.dealerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(log.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                trailing: Text('+₹${log.amount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 16)),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }
}
