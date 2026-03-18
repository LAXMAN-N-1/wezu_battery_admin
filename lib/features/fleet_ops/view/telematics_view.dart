import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/telemetry_model.dart';
import '../data/repositories/fleet_ops_repository.dart';

class TelematicsView extends StatefulWidget {
  const TelematicsView({super.key});

  @override
  State<TelematicsView> createState() => _TelematicsViewState();
}

class _TelematicsViewState extends State<TelematicsView> {
  final FleetOpsRepository _repository = FleetOpsRepository();
  List<TelemetryData> _history = [];
  bool _isLoading = false;
  int? _selectedBatteryId;

  Future<void> _searchTelematics(String id) async {
    final bid = int.tryParse(id);
    if (bid == null) return;
    
    setState(() {
      _isLoading = true;
      _selectedBatteryId = bid;
    });
    
    final data = await _repository.getBatteryTelematics(bid);
    setState(() {
      _history = data;
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
                  Text('Fleet Telematics', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Detailed movement history, telemetry logs, and state-of-charge analysis.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search Battery ID (e.g. 101)',
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: _searchTelematics,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Expanded(
            child: Row(
              children: [
                // History List
                Expanded(
                  flex: 3,
                  child: AdvancedCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Movement History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        Expanded(
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : _history.isEmpty 
                                ? Center(child: Text(_selectedBatteryId == null ? 'Enter a Battery ID to view history' : 'No telematics found for this battery', style: const TextStyle(color: Colors.white38)))
                                : AdvancedTable(
                                    columns: const ['Timestamp', 'Location (Lat, Lng)', 'Speed', 'SoC', 'Temp', 'Voltage'],
                                    rows: _history.map((t) {
                                      return [
                                        Text(_formatFullTime(t.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        Text('${t.latitude?.toStringAsFixed(4) ?? "N/A"}, ${t.longitude?.toStringAsFixed(4) ?? "N/A"}', style: const TextStyle(color: Colors.white70)),
                                        Text('${t.speedKmph?.toStringAsFixed(1) ?? "0.0"} km/h', style: const TextStyle(color: Colors.white70)),
                                        _buildMiniSoC(t.soc ?? 0),
                                        Text('${t.temperature?.toStringAsFixed(1) ?? "0"}°C', style: TextStyle(color: (t.temperature ?? 0) > 45 ? Colors.red : Colors.green)),
                                        Text('${t.voltage?.toStringAsFixed(1) ?? "0"}V', style: const TextStyle(color: Colors.white54)),
                                      ];
                                    }).toList(),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Analytics / Path
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: AdvancedCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SoC Trend (24h)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 20),
                              Expanded(
                                child: _history.isEmpty 
                                  ? const Center(child: Icon(Icons.show_chart, color: Colors.white10, size: 64))
                                  : LineChart(_buildSoCChart()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AdvancedCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Speed Analytics', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 20),
                              Expanded(
                                child: _history.isEmpty 
                                  ? const Center(child: Icon(Icons.bar_chart, color: Colors.white10, size: 64))
                                  : BarChart(_buildSpeedChart()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildMiniSoC(double soc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (soc > 20 ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('${soc.toInt()}%', style: TextStyle(color: soc > 20 ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  LineChartData _buildSoCChart() {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.soc ?? 0)).toList().reversed.toList(),
          isCurved: true,
          color: const Color(0xFF3B82F6),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
        ),
      ],
    );
  }

  BarChartData _buildSpeedChart() {
    return BarChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: _history.take(10).toList().asMap().entries.map((e) => BarChartGroupData(
        x: e.key,
        barRods: [BarChartRodData(toY: e.value.speedKmph ?? 0, color: const Color(0xFF10B981), width: 12, borderRadius: BorderRadius.circular(4))],
      )).toList(),
    );
  }

  String _formatFullTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, "0")}:${dt.second.toString().padLeft(2, "0")} | ${dt.day}/${dt.month}';
  }
}
