import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationsView extends ConsumerStatefulWidget {
  const StationsView({super.key});

  @override
  ConsumerState<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends ConsumerState<StationsView>
    with SingleTickerProviderStateMixin {
  final StationRepository _repository = StationRepository();
  final Completer<GoogleMapController> _controller = Completer();
  late TabController _tabController;

  List<Station> _stations = [];
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Station? _selectedStation;
  bool _showMapOnMobile = false;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1100;

    return Container(
      color: isDark ? AppColors.deepBg : AppColors.lightBg,
      child: isMobile
          ? _buildMobileLayout(isDark)
          : _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        _buildMobileHeader(isDark),
        Expanded(
          child: IndexedStack(
            index: _showMapOnMobile ? 1 : 0,
            children: [
              _buildListPanel(isDark, true),
              _buildMapPanel(isDark, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: isDark ? AppColors.surface : Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stations',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              _buildViewToggle(isDark),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(isDark),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(
            'List',
            !_showMapOnMobile,
            isDark,
            () => setState(() => _showMapOnMobile = false),
          ),
          _toggleBtn(
            'Map',
            _showMapOnMobile,
            isDark,
            () => setState(() => _showMapOnMobile = true),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
    String label,
    bool active,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.accentBlue : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildListPanel(isDark, false)),
        Expanded(flex: 7, child: _buildMapPanel(isDark, false)),
      ],
    );
  }

  Widget _buildListPanel(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? AppColors.cardBorder
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Network',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time status of your charging infrastructure',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSearchField(isDark),
                ],
              ),
            ),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    itemCount: _stations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      return _buildStationCard(station, isDark)
                          .animate()
                          .fadeIn(delay: (index * 100).ms, duration: 600.ms)
                          .slideX(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorder
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by station ID or location...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(Station station, bool isDark) {
    final isSelected = _selectedStation?.id == station.id;
    return GestureDetector(
      onTap: () => _onStationSelected(station),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.accentBlue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.05))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentBlue.withValues(alpha: 0.4)
                : (isDark
                      ? AppColors.cardBorder
                      : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                _buildStatusBadge(station.status, isDark),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              station.address,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetric(
                  '${station.availableBatteries}',
                  'Available',
                  Icons.battery_charging_full_rounded,
                  AppColors.emeraldSuccess,
                  isDark,
                ),
                const SizedBox(width: 24),
                _buildMetric(
                  '${station.emptySlots}',
                  'Slots',
                  Icons.check_box_outline_blank_rounded,
                  AppColors.primaryOrange,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color;
    IconData icon;
    switch (status) {
      case 'active':
        color = AppColors.emeraldSuccess;
        icon = Icons.check_circle_rounded;
        break;
      case 'maintenance':
        color = AppColors.amberWarning;
        icon = Icons.build_rounded;
        break;
      default:
        color = AppColors.crimsonError;
        icon = Icons.error_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPanel(bool isDark, bool isMobile) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          style: isDark ? _mapStyle : null,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mapActionBtn(Icons.my_location_rounded, isDark, () {}),
              const SizedBox(height: 12),
              _mapActionBtn(
                Icons.center_focus_strong_rounded,
                isDark,
                () async {
                  final controller = await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(_initialPosition),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapActionBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.cardBorder
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }
}
