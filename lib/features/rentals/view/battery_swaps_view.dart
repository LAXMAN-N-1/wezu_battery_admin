import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/swap_model.dart';
import '../data/repositories/rental_repository.dart';

class BatterySwapsView extends StatefulWidget {
  const BatterySwapsView({super.key});

  @override
  State<BatterySwapsView> createState() => _BatterySwapsViewState();
}

class _BatterySwapsViewState extends State<BatterySwapsView> {
  final RentalRepository _repository = RentalRepository();
  List<SwapSession> _swaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final swaps = await _repository.getSwaps();
    setState(() {
      _swaps = swaps;
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
                  Text('Battery Swaps', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Track all battery exchange sessions across station network.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
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
                : _swaps.isEmpty
                    ? const Center(child: Text('No swap sessions found.', style: TextStyle(color: Colors.white54)))
                    : AdvancedTable(
                        columns: const ['Swap ID', 'User', 'Station ID', 'Old SoC', 'New SoC', 'Status', 'Time'],
                        rows: _swaps.map((s) {
                          return [
                            Text('#${s.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(s.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Station ${s.stationId}', style: const TextStyle(color: Colors.white70)),
                            _buildSoCIndicator(s.oldBatterySoc),
                            _buildSoCIndicator(s.newBatterySoc),
                            StatusBadge(status: s.status),
                            Text(DateFormat('HH:mm | MMM dd').format(s.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ];
                        }).toList(),
                      ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildSoCIndicator(double soc) {
    Color color = Colors.green;
    if (soc < 20) {
      color = Colors.red;
    } else if (soc < 50) {
      color = Colors.orange;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('${soc.toInt()}%', style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
