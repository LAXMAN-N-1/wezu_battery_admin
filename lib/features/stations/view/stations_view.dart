import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // TODO: Re-enable with valid API key
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'dart:async'; // Needed for Completer when maps is re-enabled
import '../data/models/station.dart';
import '../data/providers/stations_provider.dart';
import 'station_form_view.dart';
import 'station_specs_view.dart';

class StationsView extends ConsumerStatefulWidget {
  const StationsView({super.key});

  @override
  ConsumerState<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends ConsumerState<StationsView> {
  // TODO: Re-enable when Google Maps API key is configured
  // final Completer<GoogleMapController> _controller = Completer();
  // static const CameraPosition _initialPosition = CameraPosition(
  //   target: LatLng(17.4435, 78.3772),
  //   zoom: 12,
  // );
  // final String _mapStyle = '...';

  Station? _selectedStation;

  void _onStationSelected(Station station) {
    setState(() => _selectedStation = station);
    // TODO: Re-enable camera animation when Google Maps API key is configured
    // final GoogleMapController controller = await _controller.future;
    // controller.animateCamera(...);
  }

  void _onEdit(Station station) async {
    await showDialog(
      context: context,
      builder: (context) => StationFormDialog(station: station),
    );
    // Refresh _selectedStation from provider after dialog closes so the
    // detail panel immediately shows updated slots/phone number
    if (_selectedStation?.id == station.id) {
      final updatedList = ref.read(stationsProvider).valueOrNull ?? [];
      final updated = updatedList.where((s) => s.id == station.id).firstOrNull;
      if (updated != null) {
        setState(() => _selectedStation = updated);
      }
    }
  }

  void _onDelete(Station station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Station',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${station.name}?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(stationsProvider.notifier).deleteStation(station.id);
              if (_selectedStation?.id == station.id) {
                setState(() => _selectedStation = null);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Station deleted successfully'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final isMobile = MediaQuery.of(context).size.width < 1024;

    if (isMobile) {
      return Column(
        children: [
          // Map Panel on top for mobile
          SizedBox(height: 250, child: _buildMapPanel(stationsAsync)),
          // List Panel at bottom
          Expanded(child: _buildListPanel(stationsAsync)),
        ],
      );
    }

    return Row(
      children: [
        // List Panel
        Expanded(
          flex: 1, // 33% width
          child: _buildListPanel(stationsAsync),
        ),
        // Map Panel
        Expanded(
          flex: 2, // 66% width
          child: _buildMapPanel(stationsAsync),
        ),
      ],
    );
  }

  Widget _buildListPanel(AsyncValue<List<Station>> stationsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Stations',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const StationFormDialog(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
            child: stationsAsync.when(
              data: (stations) {
                if (stations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No stations found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    final isSelected = _selectedStation?.id == station.id;

                    return Card(
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(
                                color: Colors.blue.withValues(alpha: 0.05),
                              )
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        isThreeLine: true,
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
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildBadge(
                                  '${station.totalSlots} Total',
                                  Colors.blue,
                                  Icons.grid_view,
                                ),
                                _buildBadge(
                                  '${station.availableBatteries} Bats',
                                  Colors.green,
                                  Icons.battery_charging_full,
                                ),
                                _buildBadge(
                                  '${station.emptySlots} Empty',
                                  Colors.orange,
                                  Icons.check_box_outline_blank,
                                ),
                                _buildStatusBadge(station.status),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white54,
                            size: 20,
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _onEdit(station);
                            } else if (value == 'delete') {
                              _onDelete(station);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading stations: $error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Re-enable full map implementation when Google Maps API key is configured
  // Original GoogleMap implementation is preserved below in comments.
  Widget _buildMapPanel(AsyncValue<List<Station>> stationsAsync) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Map View',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure a Google Maps API key\nto enable the interactive map.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
            ),
            if (_selectedStation != null) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.ev_station,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStation!.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _selectedStation!.address,
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stats row
                    Row(
                      children: [
                        infoChip(
                          '${_selectedStation!.totalSlots} Slots',
                          Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        infoChip(
                          '${_selectedStation!.availableBatteries} Bats',
                          Colors.green,
                        ),
                        const SizedBox(width: 6),
                        infoChip(
                          _selectedStation!.status.toUpperCase(),
                          _selectedStation!.status == 'active'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                    if (_selectedStation!.contactPhone?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 12,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedStation!.contactPhone!,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onEdit(_selectedStation!),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white12),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showStationSpecsSheet(
                              context,
                              _selectedStation!,
                            ),
                            icon: const Icon(
                              Icons.electrical_services,
                              size: 14,
                            ),
                            label: const Text('⚡ Specs'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    // --- ORIGINAL MAP CODE (commented out) ---
    // return Stack(
    //   children: [
    //     stationsAsync.when(
    //       data: (stations) {
    //         final markers = stations.map((station) => Marker(
    //           markerId: MarkerId(station.id.toString()),
    //           position: LatLng(station.latitude, station.longitude),
    //           infoWindow: InfoWindow(
    //             title: station.name,
    //             snippet: '\${station.availableBatteries} Batteries Available',
    //           ),
    //           onTap: () => setState(() => _selectedStation = station),
    //         )).toSet();
    //         return GoogleMap(
    //           mapType: MapType.normal,
    //           style: _mapStyle,
    //           initialCameraPosition: _initialPosition,
    //           onMapCreated: (controller) {
    //             if (!_controller.isCompleted) _controller.complete(controller);
    //           },
    //           markers: markers,
    //           myLocationButtonEnabled: false,
    //           zoomControlsEnabled: false,
    //         );
    //       },
    //       loading: () => const Center(child: CircularProgressIndicator()),
    //       error: (_, __) => const SizedBox(),
    //     ),
    //     Positioned(
    //       bottom: 16, right: 16,
    //       child: FloatingActionButton.small(
    //         onPressed: () async {
    //           if (_controller.isCompleted) {
    //             final c = await _controller.future;
    //             c.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
    //           }
    //         },
    //         backgroundColor: const Color(0xFF1E293B),
    //         child: const Icon(Icons.center_focus_strong, color: Colors.white),
    //       ),
    //     ),
    //   ],
    // );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
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
  }

  Widget _buildStatusBadge(String status) {
    final Color color;
    final IconData icon;
    final String label;

    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF22C55E); // green
        icon = Icons.check_circle_outline;
        label = 'Active';
        break;
      case 'maintenance':
        color = const Color(0xFFF59E0B); // amber
        icon = Icons.construction_outlined;
        label = 'Maintenance';
        break;
      case 'inactive':
        color = const Color(0xFFEF4444); // red
        icon = Icons.cancel_outlined;
        label = 'Inactive';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Small colored chip used in the station detail panel
Widget infoChip(String label, Color color) {
  final Widget infoChip = Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  return infoChip;
}
