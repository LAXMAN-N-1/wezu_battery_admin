import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import 'dart:async';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class StationMapView extends StatefulWidget {
  const StationMapView({super.key});

  @override
  State<StationMapView> createState() => _StationMapViewState();
}

class _StationMapViewState extends SafeState<StationMapView> {
  final StationRepository _repository = StationRepository();
  final Completer<GoogleMapController> _controller = Completer();
  static const bool _mapsEnabled = bool.fromEnvironment(
    'ENABLE_GOOGLE_MAPS',
    defaultValue: false,
  );

  List<Station> _stations = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<Marker> _markers = {};
  Station? _selectedStation;
  String? _filterStatus;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(17.4435, 78.3772),
    zoom: 12,
  );

  final String _mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.getStationsPaginated(
        status: _filterStatus,
      );
      final stations = data['stations'] as List<Station>;
      final markers = stations.map((s) {
        return Marker(
          markerId: MarkerId(s.id.toString()),
          position: LatLng(s.latitude, s.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(s.status)),
          infoWindow: InfoWindow(
            title: s.name,
            snippet: '${s.availableBatteries} batteries • ${s.statusDisplay}',
          ),
          onTap: () => setState(() => _selectedStation = s),
        );
      }).toSet();

      setState(() {
        _stations = stations;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load station map data.';
      });
    }
  }

  double _markerHue(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return BitmapDescriptor.hueGreen;
      case 'MAINTENANCE':
        return BitmapDescriptor.hueOrange;
      case 'OFFLINE':
        return BitmapDescriptor.hueRed;
      case 'ERROR':
        return BitmapDescriptor.hueRed;
      case 'CLOSED':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return const Color(0xFF22C55E);
      case 'MAINTENANCE':
        return const Color(0xFFF59E0B);
      case 'OFFLINE':
        return const Color(0xFFEF4444);
      case 'ERROR':
        return const Color(0xFFEF4444);
      case 'CLOSED':
        return Colors.white38;
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<void> _onStationSelected(Station station) async {
    setState(() => _selectedStation = station);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(station.latitude, station.longitude),
          zoom: 15,
        ),
      ),
    );
    controller.showMarkerInfoWindow(MarkerId(station.id.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Panel — Station List
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Station Map',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 4),
                      Text(
                        '${_stations.length} stations on map',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          // Client-side filter for speed
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Search stations...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                      const SizedBox(height: 12),
                      // Status legend
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _legendDot('Operational', const Color(0xFF22C55E)),
                          _legendDot('Maintenance', const Color(0xFFF59E0B)),
                          _legendDot('Offline', const Color(0xFFEF4444)),
                          _legendDot('Closed', Colors.white38),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: _loadData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _stations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final station = _stations[index];
                            final isSelected =
                                _selectedStation?.id == station.id;

                            return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(
                                              0xFF3B82F6,
                                            ).withValues(alpha: 0.5)
                                          : Colors.white.withValues(
                                              alpha: 0.04,
                                            ),
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () => _onStationSelected(station),
                                    contentPadding: const EdgeInsets.all(14),
                                    title: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _statusColor(station.status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            station.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          station.address,
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _badge(
                                              '${station.availableBatteries} Bats',
                                              const Color(0xFF22C55E),
                                              Icons.battery_charging_full,
                                            ),
                                            const SizedBox(width: 6),
                                            _badge(
                                              '${station.availableSlots} Free',
                                              const Color(0xFF3B82F6),
                                              Icons.space_dashboard_outlined,
                                            ),
                                            if (station.rating > 0) ...[
                                              const SizedBox(width: 6),
                                              _badge(
                                                station.rating.toStringAsFixed(
                                                  1,
                                                ),
                                                const Color(0xFFF59E0B),
                                                Icons.star,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  duration: 300.ms,
                                  delay: (index * 40).ms,
                                )
                                .slideX(begin: -0.05);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Right Panel — Map
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              if (!kIsWeb || _mapsEnabled)
                GoogleMap(
                  mapType: MapType.normal,
                  style: _mapStyle,
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: _markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                )
              else
                Container(
                  color: const Color(0xFF0F172A),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: Colors.white24,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Map is disabled in this build.',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set ENABLE_GOOGLE_MAPS=true and configure a valid Google Maps key to enable interactive maps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              // Top-right controls
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      onPressed: (!kIsWeb || _mapsEnabled)
                          ? () async {
                              final controller = await _controller.future;
                              controller.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  _initialPosition,
                                ),
                              );
                            }
                          : null,
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.center_focus_strong,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'refresh',
                      onPressed: _loadData,
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              // Selected station detail card
              if (_selectedStation != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildSelectedCard(
                    _selectedStation!,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white54, fontSize: 10)),
    ],
  );

  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildSelectedCard(Station s) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _statusColor(s.status).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.ev_station,
            color: _statusColor(s.status),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                s.address,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge(
                    '${s.availableBatteries} Batteries',
                    const Color(0xFF22C55E),
                    Icons.battery_charging_full,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    '${s.availableSlots} Slots Free',
                    const Color(0xFF3B82F6),
                    Icons.space_dashboard_outlined,
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: s.status),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          onPressed: () => setState(() => _selectedStation = null),
        ),
      ],
    ),
  );
}
