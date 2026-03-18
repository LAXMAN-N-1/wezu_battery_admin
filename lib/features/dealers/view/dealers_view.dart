import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/dealer.dart';
import '../data/repositories/dealer_repository.dart';

class DealersView extends StatefulWidget {
  const DealersView({super.key});

  @override
  State<DealersView> createState() => _DealersViewState();
}

class _DealersViewState extends State<DealersView> {
  final DealerRepository _repository = DealerRepository();
  List<DealerProfile> _dealers = [];
  DealerStats? _stats;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getDealers(search: _searchQuery.isNotEmpty ? _searchQuery : null),
      _repository.getDealerStats(),
    ]);
    
    setState(() {
      _dealers = (results[0] as Map<String, dynamic>)['dealers'] as List<DealerProfile>;
      _stats = results[1] as DealerStats;
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
          PageHeader(
            title: 'All Dealers',
            subtitle: 'View and manage active dealers in your network, monitor their status and financial performance.',
            actionButton: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _loadData,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Dealer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            searchField: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) {
                _searchQuery = v;
                _loadData();
              },
              decoration: InputDecoration(
                hintText: 'Search business name, city...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats Cards
          Row(
            children: [
              _buildStatCard('Active Dealers', _stats?.totalActiveDealers.toString() ?? '0', Icons.handshake_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Pending Onboardings', _stats?.pendingOnboardings.toString() ?? '0', Icons.hourglass_top_outlined, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildStatCard('All-time Commissions', '₹${_stats?.totalCommissionsPaid.toStringAsFixed(2) ?? '0.00'}', Icons.payments_outlined, const Color(0xFF22C55E)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Dealers Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading 
              ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
              : Column(
                  children: [
                    AdvancedTable(
                      columns: const ['Business Name', 'City', 'Contact', 'GST / PAN', 'Status', 'Joined At', 'Actions'],
                      rows: _dealers.map((d) {
                        return [
                          Text(d.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(d.city, style: const TextStyle(color: Colors.white70)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.contactPerson, style: const TextStyle(color: Colors.white)),
                              Text(d.contactPhone, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.gstNumber ?? 'N/A', style: const TextStyle(color: Colors.white70)),
                              Text(d.panNumber ?? 'N/A', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                          StatusBadge(status: d.isActive ? 'Active' : 'Inactive'),
                          Text(d.createdAt.toString().split(' ')[0], style: const TextStyle(color: Colors.white54)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF3B82F6)), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.white54), onPressed: () {}),
                            ],
                          ),
                        ];
                      }).toList(),
                    ),
                  ],
                ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
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
                Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
