import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationPerformanceView extends StatefulWidget {
  const StationPerformanceView({super.key});

  @override
  State<StationPerformanceView> createState() => _StationPerformanceViewState();
}

class _StationPerformanceViewState extends State<StationPerformanceView> {
  final StationRepository _repository = StationRepository();
  List<StationPerformanceSummary> _stations = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getAllPerformance();
      setState(() {
        _stations = data['stations'] as List<StationPerformanceSummary>;
        _summary = (data['summary'] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Station Performance',
            subtitle: 'Utilization rates, ratings, battery availability, and operational metrics across all stations.',
            actionButton: _buildRefreshButton(),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Summary Stats
          Row(
            children: [
              _buildStatCard('Total Stations', (_summary['total_stations'] ?? 0).toString(), Icons.ev_station_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Avg Utilization', '${(_summary['avg_utilization'] ?? 0.0).toStringAsFixed(1)}%', Icons.speed_outlined, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildStatCard('Avg Rating', (_summary['avg_rating'] ?? 0.0).toStringAsFixed(1), Icons.star_outline, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildStatCard('Total Batteries', (_summary['total_available_batteries'] ?? 0).toString(), Icons.battery_charging_full_outlined, const Color(0xFF8B5CF6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Performance Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : _stations.isEmpty
                    ? SizedBox(
                        height: 200,
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.analytics_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No performance data available', style: GoogleFonts.inter(color: Colors.white54)),
                        ])),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              const Icon(Icons.trending_up, color: Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 10),
                              Text('Performance Comparison', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Text('${_stations.length} stations', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                            ]),
                          ),
                          AdvancedTable(
                            columns: const ['Station', 'Status', 'Utilization', 'Slots', 'Batteries', 'Rating', 'Reviews', 'Power'],
                            rows: _stations.map((s) {
                              return [
                                // Station name
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(s.stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    if (s.city != null) Text(s.city!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                                // Status
                                StatusBadge(status: s.status),
                                // Utilization bar
                                _utilizationBar(s.utilizationPercentage),
                                // Slots
                                Text('${s.occupiedSlots}/${s.totalSlots}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                // Batteries
                                Text('${s.availableBatteries}', style: TextStyle(
                                  color: s.availableBatteries > 0 ? const Color(0xFF22C55E) : Colors.white38,
                                  fontWeight: FontWeight.bold, fontSize: 13,
                                )),
                                // Rating
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.star, size: 14, color: s.rating > 0 ? const Color(0xFFF59E0B) : Colors.white24),
                                  const SizedBox(width: 3),
                                  Text(s.rating.toStringAsFixed(1), style: TextStyle(color: s.rating > 0 ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                                ]),
                                // Reviews
                                Text('${s.totalReviews}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                // Power
                                Text(s.powerRatingKw != null ? '${s.powerRatingKw} kW' : '—', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ];
                            }).toList(),
                          ),
                        ],
                      ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),

          const SizedBox(height: 24),

          // Top / Bottom performers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPerformerCard('Top Performers', _getTopPerformers(), const Color(0xFF22C55E), Icons.trending_up)),
              const SizedBox(width: 20),
              Expanded(child: _buildPerformerCard('Needs Attention', _getBottomPerformers(), const Color(0xFFEF4444), Icons.trending_down)),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() => Container(
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70, size: 20), onPressed: _loadData, tooltip: 'Refresh'),
  );

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

  Widget _utilizationBar(double pct) {
    Color barColor;
    if (pct >= 80) {
      barColor = const Color(0xFFEF4444);
    } else if (pct >= 50) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFF22C55E);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 60, height: 8, child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct / 100, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(barColor)),
      )),
      const SizedBox(width: 6),
      Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  List<StationPerformanceSummary> _getTopPerformers() {
    final sorted = [..._stations]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  List<StationPerformanceSummary> _getBottomPerformers() {
    final sorted = [..._stations]..sort((a, b) => a.utilizationPercentage.compareTo(b.utilizationPercentage));
    return sorted.where((s) => s.status.toUpperCase() != 'CLOSED').take(5).toList();
  }

  Widget _buildPerformerCard(String title, List<StationPerformanceSummary> items, Color color, IconData icon) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No data', style: GoogleFonts.inter(color: Colors.white54)),
            ))
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.stationName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(s.city ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(s.rating.toStringAsFixed(1), style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                    Text('${s.utilizationPercentage.toStringAsFixed(0)}% util', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                  ]),
                ]),
              );
            }),
        ],
      ),
    );
  }
}
