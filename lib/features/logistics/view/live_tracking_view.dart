import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/logistics_repository.dart';

class LiveTrackingView extends StatefulWidget {
  const LiveTrackingView({super.key});
  @override
  State<LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<LiveTrackingView> {
  final LogisticsRepository _repo = LogisticsRepository();
  bool _isLoading = true;
  List<dynamic> _tracking = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _repo.getLiveTracking();
    setState(() { _tracking = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Live Tracking', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('Real-time delivery tracking and driver positions.', style: TextStyle(color: Colors.white54)),
        ]),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${_tracking.length} Active', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
            ])),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
        ]),
      ]).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 24),

      Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _tracking.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_off, color: Colors.white24, size: 64),
              const SizedBox(height: 12),
              Text('No active deliveries', style: TextStyle(color: Colors.white38, fontSize: 16)),
            ]))
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Left: Track List
              SizedBox(width: 420, child: ListView.builder(
                itemCount: _tracking.length,
                itemBuilder: (ctx, i) => _trackingCard(_tracking[i], i),
              )),
              const SizedBox(width: 16),
              // Right: Map placeholder / Stats
              Expanded(child: AdvancedCard(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Delivery Map', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Expanded(child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                    child: Stack(children: [
                      // Grid lines to simulate map
                      ...List.generate(10, (i) => Positioned(top: i * 40.0, left: 0, right: 0, child: Container(height: 1, color: Colors.white.withValues(alpha: 0.03)))),
                      ...List.generate(10, (i) => Positioned(left: i * 60.0, top: 0, bottom: 0, child: Container(width: 1, color: Colors.white.withValues(alpha: 0.03)))),
                      // Driver pins
                      ..._tracking.asMap().entries.where((e) => e.value['driver'] != null && e.value['driver']['latitude'] != null).map((e) {
                        final d = e.value['driver'];
                        return Positioned(
                          left: ((d['longitude'] as num? ?? 78.37) - 78.33) * 800,
                          top: ((d['latitude'] as num? ?? 17.44) - 17.42) * 800,
                          child: Tooltip(message: d['name'] ?? 'Driver', child: Container(padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFF3B82F6), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), blurRadius: 8)]),
                            child: const Icon(Icons.delivery_dining, color: Colors.white, size: 14))),
                        );
                      }),
                      // Center label
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.map_outlined, color: Colors.white.withValues(alpha: 0.08), size: 60),
                        const SizedBox(height: 4),
                        Text('Live GPS Positions', style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 11)),
                      ])),
                    ]),
                  )),
                ]),
              )),
            ]),
      ),
    ]));
  }

  Widget _trackingCard(Map<String, dynamic> t, int index) {
    final driver = t['driver'] as Map<String, dynamic>?;
    final isOnline = driver?['is_online'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdvancedCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping, color: Color(0xFF3B82F6), size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #${t['order_id']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text((t['order_type'] ?? '').toString().replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
            StatusBadge(status: (t['status'] ?? '').toString().toUpperCase()),
          ]),
          const SizedBox(height: 12),

          // Route
          Row(children: [
            Column(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              Container(width: 1, height: 20, color: Colors.white24),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
            ]),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['origin'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Text(t['destination'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
            ])),
          ]),

          if (driver != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            Row(children: [
              CircleAvatar(radius: 14, backgroundColor: isOnline ? const Color(0xFF22C55E).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                child: Icon(Icons.person, color: isOnline ? const Color(0xFF22C55E) : Colors.white38, size: 14)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(driver['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(driver['vehicle_plate'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: (isOnline ? const Color(0xFF22C55E) : Colors.white24).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isOnline ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: isOnline ? const Color(0xFF22C55E) : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold))),
            ]),
          ],
        ]),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 50)).slideX(begin: -0.05);
  }
}
