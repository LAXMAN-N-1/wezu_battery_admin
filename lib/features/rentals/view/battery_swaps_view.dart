import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/swap_model.dart';
import '../data/repositories/rental_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class BatterySwapsView extends StatefulWidget {
  const BatterySwapsView({super.key});

  @override
  State<BatterySwapsView> createState() => _BatterySwapsViewState();
}

class _BatterySwapsViewState extends SafeState<BatterySwapsView> {
  final RentalRepository _repository = RentalRepository();
  List<SwapSession> _swaps = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  SwapSession? _selectedSwap;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final swaps = await _repository.getSwaps();
    setState(() { _swaps = swaps; _isLoading = false; });
  }

  List<SwapSession> get _filtered => _statusFilter == 'all'
      ? _swaps
      : _swaps.where((s) => s.status.toLowerCase() == _statusFilter.toLowerCase()).toList();

  @override
  Widget build(BuildContext context) {
    final completed = _swaps.where((s) => s.status.toLowerCase() == 'completed').length;
    final pending = _swaps.where((s) => s.status.toLowerCase() == 'pending').length;
    final avgSocGain = _swaps.isNotEmpty
        ? _swaps.fold<double>(0, (sum, s) => sum + (s.newBatterySoc - s.oldBatterySoc)) / _swaps.length
        : 0.0;

    return Row(
      children: [
        Expanded(
          flex: _selectedSwap != null ? 3 : 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Battery Swaps',
                  subtitle: 'Track all battery exchange sessions across station network.',
                  actionButton: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Stats
                Row(
                  children: [
                    _buildStat('Total Swaps', '${_swaps.length}', Icons.swap_horiz, const Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    _buildStat('Completed', '$completed', Icons.check_circle_outline, const Color(0xFF22C55E)),
                    const SizedBox(width: 12),
                    _buildStat('Pending', '$pending', Icons.pending_outlined, const Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    _buildStat('Avg SoC Gain', '+${avgSocGain.toStringAsFixed(1)}%', Icons.trending_up, const Color(0xFF8B5CF6)),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 20),

                // Filter chips
                Row(
                  children: ['all', 'completed', 'pending'].map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _statusFilter == s,
                      label: Text(s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1), style: TextStyle(color: _statusFilter == s ? Colors.white : Colors.white54, fontSize: 12)),
                      selectedColor: const Color(0xFF3B82F6), backgroundColor: const Color(0xFF1E293B),
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setState(() => _statusFilter = s),
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
                        ? const Center(child: Text('No swap sessions found.', style: TextStyle(color: Colors.white54)))
                        : AdvancedTable(
                            columns: const ['ID', 'User', 'Station', 'Old SoC', '→', 'New SoC', 'Status', 'Time'],
                            rows: _filtered.map((s) => [
                              Text('#${s.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(s.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Station ${s.stationId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              _buildSoCIndicator(s.oldBatterySoc),
                              const Icon(Icons.arrow_forward, color: Colors.white24, size: 14),
                              _buildSoCIndicator(s.newBatterySoc),
                              StatusBadge(status: s.status),
                              Text(DateFormat('HH:mm | MMM dd').format(s.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ]).toList(),
                            onRowTap: (i) => setState(() => _selectedSwap = _filtered[i]),
                          ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              ],
            ),
          ),
        ),
        if (_selectedSwap != null)
          Container(
            width: 340,
            decoration: const BoxDecoration(color: Color(0xFF0F172A), border: Border(left: BorderSide(color: Colors.white12))),
            child: _buildSwapDetail(_selectedSwap!),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2),
      ],
    );
  }

  Widget _buildSwapDetail(SwapSession s) {
    final socGain = s.newBatterySoc - s.oldBatterySoc;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Swap #${s.id}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => setState(() => _selectedSwap = null)),
          ]),
          const SizedBox(height: 4),
          StatusBadge(status: s.status),
          const Divider(color: Colors.white12, height: 32),
          _infoRow('User', s.userName),
          _infoRow('Station ID', '${s.stationId}'),
          _infoRow('Rental ID', '${s.rentalId}'),
          _infoRow('Time', DateFormat('MMM dd, yyyy HH:mm').format(s.createdAt)),
          const Divider(color: Colors.white12, height: 24),
          Text('BATTERY EXCHANGE', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _socCard('Old Battery', s.oldBatteryId, s.oldBatterySoc, const Color(0xFFEF4444))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.swap_horiz, color: Colors.white38)),
            Expanded(child: _socCard('New Battery', s.newBatteryId, s.newBatterySoc, const Color(0xFF22C55E))),
          ]),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.trending_up, color: Color(0xFF22C55E), size: 20),
              const SizedBox(width: 12),
              Text('SoC Gain: +${socGain.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _socCard(String label, int batteryId, double soc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('BAT_$batteryId', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text('${soc.toInt()}%', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

  Widget _buildSoCIndicator(double soc) {
    final color = soc < 20 ? const Color(0xFFEF4444) : soc < 50 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('${soc.toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    ]);
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
