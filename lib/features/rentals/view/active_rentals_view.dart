import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/rental_model.dart';
import '../data/repositories/rental_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class ActiveRentalsView extends StatefulWidget {
  const ActiveRentalsView({super.key});

  @override
  State<ActiveRentalsView> createState() => _ActiveRentalsViewState();
}

class _ActiveRentalsViewState extends SafeState<ActiveRentalsView> {
  final RentalRepository _repository = RentalRepository();
  List<Rental> _rentals = [];
  RentalStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getActiveRentals(),
      _repository.getRentalStats(),
    ]);
    
    setState(() {
      _rentals = results[0] as List<Rental>;
      _stats = results[1] as RentalStats;
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
                  Text('Active Rentals', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Real-time tracking of all active battery rentals in the field.', style: TextStyle(fontSize: 16, color: Colors.white54)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _loadData,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // Stats Cards
          Row(
            children: [
              _buildStatCard('Active Rentals', _stats?.activeRentals.toString() ?? '0', Icons.ev_station_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Overdue', _stats?.overdueRentals.toString() ?? '0', Icons.report_problem_outlined, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildStatCard('Today\'s Revenue', '₹${_stats?.todayRevenue.toStringAsFixed(2) ?? '0.00'}', Icons.currency_rupee_outlined, const Color(0xFF22C55E)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Rentals List
          _isLoading
            ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
            : _rentals.isEmpty
                ? const Center(child: Text('No active rentals found.', style: TextStyle(color: Colors.white54)))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _rentals.length,
                    itemBuilder: (context, index) {
                      final r = _rentals[index];
                      return AdvancedCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text('Rental #${r.id}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.battery_charging_full, color: Color(0xFF3B82F6), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (r.batteryLevel ?? 100) / 100,
                                      backgroundColor: Colors.white12,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(r.batteryLevel ?? 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('STARTED', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                    Text(r.startTime.toString().split('.')[0].substring(5), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('EXPECTED END', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                    Text(r.expectedEndTime.toString().split('.')[0].substring(5), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _terminateRental(r),
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3))),
                                    child: const Text('Terminate'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                                    child: const Text('Details'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).scale(begin: const Offset(0.95, 0.95));
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }

  void _terminateRental(Rental r) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Terminate Rental', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to forcefully terminate this rental? The battery will be marked as available for other users.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final ok = await _repository.terminateRental(r.id, "Admin Force Termination");
              if (ok) {
                navigator.pop();
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
