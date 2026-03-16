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
      default: return BitmapDescriptor.hueAzure;
    }
  }

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
}
