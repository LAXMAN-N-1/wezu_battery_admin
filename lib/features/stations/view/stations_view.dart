import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationsView extends ConsumerStatefulWidget {
  const StationsView({super.key});

  @override
  ConsumerState<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends ConsumerState<StationsView> {
  late final StationRepository _repository;
  final Completer<GoogleMapController> _controller = Completer();
  
  List<Station> _stations = [];
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Station? _selectedStation;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(17.4435, 78.3772), // Hyderabad
    zoom: 12,
  );

  // Dark Map Style JSON
  final String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f3d19c"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _repository = ref.read(stationRepositoryProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stations = await _repository.getStations();
      final markers = stations.map((station) {
        return Marker(
          markerId: MarkerId(station.id.toString()),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.availableBatteries} Batteries Available',
          ),
          onTap: () => setState(() => _selectedStation = station),
        );
      }).toSet();

      setState(() {
        _stations = stations;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onStationSelected(Station station) async {
    setState(() => _selectedStation = station);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(station.latitude, station.longitude),
        zoom: 15,
      ),
    ));
    controller.showMarkerInfoWindow(MarkerId(station.id.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // List Panel
        Expanded(
          flex: 1, // 40% width
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Station Network',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _stations.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final station = _stations[index];
                            final isSelected = _selectedStation?.id == station.id;
                            
                            return Card(
                              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected 
                                  ? BorderSide(color: Colors.blue.withValues(alpha: 0.5))
                                  : BorderSide.none,
                              ),
                              child: ListTile(
                                onTap: () => _onStationSelected(station),
                                title: Text(
                                  station.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      station.address,
                                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildBadge(
                                          '${station.availableBatteries} Bats',
                                          Colors.green,
                                          Icons.battery_charging_full,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildBadge(
                                          '${station.emptySlots} Slots', 
                                          Colors.orange,
                                          Icons.check_box_outline_blank,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: _buildStatusDot(station.status),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        
        // Map Panel
        Expanded(
          flex: 2, // 60% width
          child: Stack(
            children: [
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
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () async {
                    final controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
                  },
                  backgroundColor: const Color(0xFF1E293B),
                  child: const Icon(Icons.center_focus_strong, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'active': color = Colors.green; break;
      case 'maintenance': color = Colors.orange; break;
      default: color = Colors.red;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1),
        ],
      ),
    );
  }
}
