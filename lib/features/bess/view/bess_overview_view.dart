import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/bess_models.dart';
import '../data/repositories/bess_repository.dart';

class BessOverviewView extends StatefulWidget {
  const BessOverviewView({super.key});
  @override
  State<BessOverviewView> createState() => _BessOverviewViewState();
}

class _BessOverviewViewState extends State<BessOverviewView> {
  final BessRepository _repo = BessRepository();
  BessOverviewStats? _stats;
  List<BessUnit> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getOverview(),
        _repo.getUnits(),
      ]);
      setState(() {
        _stats = results[0] as BessOverviewStats;
        _units = results[1] as List<BessUnit>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BESS Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Battery Energy Storage System — real-time monitoring', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          // Stats cards
          if (_stats != null) _buildStatsRow(),
          const SizedBox(height: 32),
          Text('BESS Units', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          ..._units.map((u) => _buildUnitCard(u)),
        ]),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Wrap(spacing: 16, runSpacing: 16, children: [
      _statCard('Total Units', '${_stats!.totalUnits}', Icons.battery_charging_full, const Color(0xFF3B82F6),
          subtitle: '${_stats!.onlineUnits} online'),
      _statCard('Total Capacity', '${_stats!.totalCapacityKwh.toStringAsFixed(0)} kWh', Icons.bolt, const Color(0xFF10B981),
          subtitle: '${_stats!.currentStoredKwh.toStringAsFixed(0)} kWh stored'),
      _statCard('Avg SoC', '${_stats!.avgSoc.toStringAsFixed(1)}%', Icons.electrical_services, const Color(0xFFF59E0B),
          subtitle: 'SoH: ${_stats!.avgSoh.toStringAsFixed(1)}%'),
      _statCard('Today\'s Energy', '${_stats!.totalEnergyTodayKwh.toStringAsFixed(0)} kWh', Icons.electric_meter, const Color(0xFF8B5CF6),
          subtitle: '₹${_stats!.totalRevenueToday.toStringAsFixed(0)} revenue'),
    ]);
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('LIVE', style: GoogleFonts.inter(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ])),
        ]),
        const SizedBox(height: 16),
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(color: color.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _buildUnitCard(BessUnit unit) {
    final statusColor = unit.status == 'online' ? Colors.green : unit.status == 'maintenance' ? Colors.orange : Colors.red;
    final socColor = unit.soc > 60 ? Colors.green : unit.soc > 30 ? Colors.orange : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.battery_charging_full, color: Color(0xFF3B82F6), size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(unit.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(unit.location, style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(unit.status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        // SoC Progress
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('State of Charge', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              Text('${unit.soc.toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: socColor, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: unit.soc / 100, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.05), color: socColor)),
          ])),
          const SizedBox(width: 24),
          _miniStat('Capacity', '${unit.capacityKwh.toStringAsFixed(0)} kWh'),
          const SizedBox(width: 24),
          _miniStat('Max Power', '${unit.maxPowerKw.toStringAsFixed(0)} kW'),
          const SizedBox(width: 24),
          _miniStat('SoH', '${unit.soh.toStringAsFixed(1)}%'),
          const SizedBox(width: 24),
          _miniStat('Temp', '${unit.temperatureC.toStringAsFixed(1)}°C'),
          const SizedBox(width: 24),
          _miniStat('Cycles', '${unit.cycleCount}'),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(children: [
      Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
    ]);
  }
}
