import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/geofence_model.dart';
import '../data/repositories/fleet_ops_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class GeofencingView extends StatefulWidget {
  const GeofencingView({super.key});

  @override
  State<GeofencingView> createState() => _GeofencingViewState();
}

class _GeofencingViewState extends SafeState<GeofencingView> {
  final FleetOpsRepository _repository = FleetOpsRepository();
  List<Geofence> _geofences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _repository.getGeofences();
    setState(() {
      _geofences = list;
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
                  Text('Geofencing & Safe Zones', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Configure virtual boundaries for fleet operation limits and station security perimeters.', style: TextStyle(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Create New Zone'),
                onPressed: _showCreateDialog,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Placeholder / UI
                Expanded(
                  flex: 2,
                  child: AdvancedCard(
                    padding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        // Dynamic Map Background Placeholder
                        Container(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=1200q=80'),
                              fit: BoxFit.cover,
                              opacity: 0.3,
                            ),
                          ),
                        ),
                        // Grid Overlay
                        CustomPaint(
                          painter: GridPainter(),
                          size: Size.infinite,
                        ),
                        // Zone Indicators (Animated Circles)
                        ..._geofences.map((g) => Positioned(
                          left: 200 + (g.id ?? 1) * 50.0,
                          top: 150 + (g.id ?? 1) * 30.0,
                          child: _buildZoneMarker(g),
                        )),
                        // Active Overlay
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.layers_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                const Text('Satellite View', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Sidebar List
                Expanded(
                  flex: 1,
                  child: AdvancedCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Active Perimeters', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        Expanded(
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: _geofences.length,
                                itemBuilder: (context, index) {
                                  final g = _geofences[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getZoneColor(g.type).withValues(alpha: 0.2),
                                      child: Icon(Icons.fence, color: _getZoneColor(g.type), size: 16),
                                    ),
                                    title: Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: Text('${g.radiusMeters}m | ${g.type}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    trailing: Switch(
                                      value: g.isActive,
                                      onChanged: (v) {},
                                      activeThumbColor: const Color(0xFF10B981),
                                    ),
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildZoneMarker(Geofence g) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _getZoneColor(g.type).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: _getZoneColor(g.type), width: 2),
          ),
          child: const Center(child: Icon(Icons.my_location, color: Colors.white54, size: 12)),
        ).animate(onPlay: (controller) => controller.repeat())
         .shimmer(duration: 2000.ms, color: _getZoneColor(g.type).withValues(alpha: 0.3)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
          child: Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ],
    );
  }

  Color _getZoneColor(String type) {
    switch (type.toLowerCase()) {
      case 'restricted_zone': return const Color(0xFFEF4444);
      case 'station_perimeter': return const Color(0xFF3B82F6);
      default: return const Color(0xFF10B981);
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Define Geofence', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Zone Name', labelStyle: TextStyle(color: Colors.white54))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1E293B),
              decoration: const InputDecoration(labelText: 'Zone Type', labelStyle: TextStyle(color: Colors.white54)),
              items: ['safe_zone', 'restricted_zone', 'station_perimeter'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Radius (Meters)', labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Create Zone')),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
