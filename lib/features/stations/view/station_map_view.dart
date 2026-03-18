<<<<<<< HEAD
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../data/models/station.dart';
import '../data/providers/stations_provider.dart';
import '../data/providers/station_performance_provider.dart';

enum MapViewMode { standard, cluster, heatmap }

class StationMapView extends ConsumerStatefulWidget {
  const StationMapView({super.key});

  @override
  ConsumerState<StationMapView> createState() => _StationMapViewState();
}

class _StationMapViewState extends ConsumerState<StationMapView> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  String? _mapStyle;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  String _statusFilter = 'all';
  MapViewMode _viewMode = MapViewMode.cluster;
  Station? _selectedStation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style_night.json');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading map style: $e');
    }
  }

  void _syncData() {
    final stations = ref.read(stationsProvider).valueOrNull ?? [];
    
    _updateMarkers(stations);
    _updateHeatmapCircles(stations);
  }

  void _updateMarkers(List<Station> stations) {
    final filtered = stations.where((s) {
      if (_statusFilter == 'all') return true;
      return s.status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    final newMarkers = filtered.map((station) {
      return Marker(
        markerId: MarkerId('station_${station.id}'),
        position: LatLng(station.latitude, station.longitude),
        clusterManagerId: _viewMode == MapViewMode.cluster 
            ? const ClusterManagerId('stations_cluster') 
            : null,
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(station.status)),
        onTap: () => _onStationTap(station),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: station.address,
        ),
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _updateHeatmapCircles(List<Station> stations) {
    if (_viewMode != MapViewMode.heatmap) {
      if (mounted && _circles.isNotEmpty) {
        setState(() => _circles = {});
      }
      return;
    }

    final rankings = ref.read(stationRankingsProvider(metric: 'rentals')).valueOrNull ?? [];
    
    final newCircles = stations.map((station) {
      final ranking = rankings.where((r) => r.stationId == station.id).firstOrNull;
      final intensity = ranking != null ? (ranking.metricValue / 100).clamp(0.1, 1.0) : 0.2;
      
      return Circle(
        circleId: CircleId('heat_${station.id}'),
        center: LatLng(station.latitude, station.longitude),
        radius: 400 + (intensity * 1200),
        fillColor: _getHeatColor(intensity).withOpacity(0.15 + (intensity * 0.35)),
        strokeWidth: 0,
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _circles = newCircles;
      });
    }
  }

  Color _getHeatColor(double intensity) {
    if (intensity < 0.3) return Colors.blueAccent;
    if (intensity < 0.6) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  double _getMarkerHue(String status) {
    switch (status.toLowerCase()) {
      case 'active': return BitmapDescriptor.hueAzure;
      case 'maintenance': return BitmapDescriptor.hueOrange;
      case 'inactive': return BitmapDescriptor.hueRed;
=======
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import 'dart:async';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationMapView extends StatefulWidget {
  const StationMapView({super.key});

  @override
  State<StationMapView> createState() => _StationMapViewState();
}

class _StationMapViewState extends State<StationMapView> {
  final StationRepository _repository = StationRepository();
  final Completer<GoogleMapController> _controller = Completer();

  List<Station> _stations = [];
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getStations(status: _filterStatus);
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
      setState(() => _isLoading = false);
    }
  }

  double _markerHue(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL': return BitmapDescriptor.hueGreen;
      case 'MAINTENANCE': return BitmapDescriptor.hueOrange;
      case 'OFFLINE': return BitmapDescriptor.hueRed;
      case 'ERROR': return BitmapDescriptor.hueRed;
      case 'CLOSED': return BitmapDescriptor.hueViolet;
>>>>>>> origin/main
      default: return BitmapDescriptor.hueAzure;
    }
  }

<<<<<<< HEAD
  void _onStationTap(Station station) {
    setState(() {
      _selectedStation = station;
    });
    _animateToLocation(LatLng(station.latitude, station.longitude), zoom: 15);
  }

  Future<void> _animateToLocation(LatLng location, {double? zoom}) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: zoom ?? 15)));
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _animateToLocation(LatLng(locations.first.latitude, locations.first.longitude), zoom: 14);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    ref.watch(stationRankingsProvider(metric: 'rentals'));

    ref.listen(stationsProvider, (previous, next) {
      if (next is AsyncData<List<Station>>) {
        _syncData();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          stationsAsync.when(
            data: (stations) {
              if (_markers.isEmpty && stations.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncData());
              }
              return GoogleMap(
                initialCameraPosition: _kInitialPosition,
                onMapCreated: (controller) {
                  _controller.complete(controller);
                  if (_mapStyle != null) controller.setMapStyle(_mapStyle);
                },
                markers: _markers,
                circles: _circles,
                clusterManagers: {
                  if (_viewMode == MapViewMode.cluster)
                    ClusterManager(
                      clusterManagerId: const ClusterManagerId('stations_cluster'),
                      onClusterTap: (cluster) {
                        _animateToLocation(cluster.position, zoom: cluster.position.latitude < 1 ? 12 : 14);
                      },
                    ),
                },
                myLocationButtonEnabled: false,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.blue)),
            error: (e, s) => Center(child: Text('Error loading map', style: GoogleFonts.inter(color: Colors.redAccent))),
          ),
          
          Positioned(top: 24, left: 24, right: 24, child: _buildHeader()),

          if (_viewMode == MapViewMode.heatmap)
            Positioned(bottom: 24, right: 24, child: _buildHeatmapLegend()),

          if (_selectedStation != null)
            Positioned(bottom: 24, left: 24, right: 200, child: _buildDetailCard(_selectedStation!)),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rental Intensity', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildLegendItem('High Demand', Colors.redAccent),
          const SizedBox(height: 8),
          _buildLegendItem('Medium Demand', Colors.orangeAccent),
          const SizedBox(height: 8),
          _buildLegendItem('Low Demand', Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(children: [
            _buildModeButton(MapViewMode.standard, Icons.place, 'Standard'),
            _buildModeButton(MapViewMode.cluster, Icons.api, 'Clustered'),
            _buildModeButton(MapViewMode.heatmap, Icons.layers, 'Heatmap'),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Active', 'active'),
            const SizedBox(width: 8),
            _buildFilterChip('Maintenance', 'maintenance'),
          ]),
        ),
        const Spacer(),
        Container(
          width: 250,
          height: 44, // Fixed height for consistent alignment
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white38, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _handleSearch(),
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: _isSearching 
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: const SizedBox(
                                width: 14, 
                                height: 14, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(MapViewMode mode, IconData icon, String tooltip) {
    final isSelected = _viewMode == mode;
    return IconButton(
      onPressed: () {
        setState(() => _viewMode = mode);
        _syncData();
      },
      icon: Icon(icon, color: isSelected ? const Color(0xFF3B82F6) : Colors.white38, size: 20),
      tooltip: tooltip,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = value;
          _selectedStation = null;
        });
        _syncData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(Station station) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ev_station, color: Color(0xFF3B82F6), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(station.address, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedStation = null),
                icon: const Icon(Icons.close, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStat('Batteries', '${station.availableBatteries}', const Color(0xFF22C55E)),
              const SizedBox(width: 12),
              _buildStat('Empty Slots', '${station.emptySlots}', const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _buildStat('Total Slots', '${station.totalSlots}', const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/stations/performance/${station.id}/${Uri.encodeComponent(station.name)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('View Analytics', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
=======
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL': return const Color(0xFF22C55E);
      case 'MAINTENANCE': return const Color(0xFFF59E0B);
      case 'OFFLINE': return const Color(0xFFEF4444);
      case 'ERROR': return const Color(0xFFEF4444);
      case 'CLOSED': return Colors.white38;
      default: return const Color(0xFF3B82F6);
    }
  }

  Future<void> _onStationSelected(Station station) async {
    setState(() => _selectedStation = station);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(station.latitude, station.longitude), zoom: 15),
    ));
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
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Station Map', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 4),
                      Text('${_stations.length} stations on map', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
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
                          prefixIcon: const Icon(Icons.search, color: Colors.white38),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _stations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final station = _stations[index];
                            final isSelected = _selectedStation?.id == station.id;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04)),
                              ),
                              child: ListTile(
                                onTap: () => _onStationSelected(station),
                                contentPadding: const EdgeInsets.all(14),
                                title: Row(children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: _statusColor(station.status), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(station.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14))),
                                ]),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(station.address, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      _badge('${station.availableBatteries} Bats', const Color(0xFF22C55E), Icons.battery_charging_full),
                                      const SizedBox(width: 6),
                                      _badge('${station.availableSlots} Free', const Color(0xFF3B82F6), Icons.space_dashboard_outlined),
                                      if (station.rating > 0) ...[
                                        const SizedBox(width: 6),
                                        _badge(station.rating.toStringAsFixed(1), const Color(0xFFF59E0B), Icons.star),
                                      ],
                                    ]),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms).slideX(begin: -0.05);
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
              // Top-right controls
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      onPressed: () async {
                        final controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
                      },
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'refresh',
                      onPressed: _loadData,
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 18),
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
                  child: _buildSelectedCard(_selectedStation!).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
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
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
    ],
  );

  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildSelectedCard(Station s) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _statusColor(s.status).withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Icon(Icons.ev_station, color: _statusColor(s.status), size: 24),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(s.address, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          _badge('${s.availableBatteries} Batteries', const Color(0xFF22C55E), Icons.battery_charging_full),
          const SizedBox(width: 8),
          _badge('${s.availableSlots} Slots Free', const Color(0xFF3B82F6), Icons.space_dashboard_outlined),
          const SizedBox(width: 8),
          StatusBadge(status: s.status),
        ]),
      ])),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
        onPressed: () => setState(() => _selectedStation = null),
      ),
    ]),
  );
>>>>>>> origin/main
}
