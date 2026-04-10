import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/station.dart';
import '../data/models/station_hours.dart';
import '../data/providers/stations_provider.dart';
import '../widgets/camera_player.dart';
import '../widgets/active_rentals_grid.dart';
import 'station_form_view.dart';
import 'operating_hours_settings_view.dart';
import 'station_specs_view.dart';

class StationsView extends ConsumerStatefulWidget {
  const StationsView({super.key});

  @override
  ConsumerState<StationsView> createState() => _StationsViewState();
}

class _StationsViewState extends ConsumerState<StationsView> {
  Station? _selectedStation;
  String _searchQuery = '';
  String? _filterStatus;

  void _onStationSelected(Station station) {
    setState(() {
      if (_selectedStation?.id == station.id) {
        _selectedStation = null;
      } else {
        _selectedStation = station;
      }
    });
  }

  void _onEdit(Station station) async {
    await showDialog(
      context: context,
      builder: (context) => StationFormDialog(station: station),
    );
    
    // Refresh detailed station if it was selected
    if (_selectedStation?.id == station.id) {
      final stations = ref.read(stationsProvider).valueOrNull ?? [];
      final updated = stations.where((s) => s.id == station.id).firstOrNull;
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
          'Are you sure you want to delete ${station.name}?\nThis action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(stationsProvider.notifier).deleteStation(station.id);
              if (_selectedStation?.id == station.id) {
                setState(() => _selectedStation = null);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${station.name} deleted successfully'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // Main Content
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: stationsAsync.when(
                    data: (stations) {
                      // Apply Filters
                      var filtered = stations.where((s) {
                        final matchesSearch = _searchQuery.isEmpty ||
                            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            s.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (s.city?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                        
                        final matchesStatus = _filterStatus == null || 
                            s.status.toUpperCase() == _filterStatus!.toUpperCase();
                        
                        return matchesSearch && matchesStatus;
                      }).toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PageHeader(
                              title: 'All Stations',
                              subtitle: 'Manage your station network — view, create, edit, and monitor health.',
                              actionButton: ElevatedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => const StationFormDialog(),
                                ),
                                icon: const Icon(Icons.add_location_alt, size: 18),
                                label: const Text('Add Station'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              searchField: TextField(
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search stations...',
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFF1E293B),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                                  ),
                                ),
                              ),
                            ),

                            // Stats Row
                            _buildStatsRow(stations),
                            const SizedBox(height: 24),

                            // Table Section
                            AdvancedCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${filtered.length} Stations Found',
                                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                                        ),
                                        
                                        _buildFilterDropdown(),
                                      ],
                                    ),
                                  ),
                                  AdvancedTable(
                                    columns: const ['Station', 'City', 'Status', 'Slots', 'Bats', 'Actions'],
                                    rows: filtered.map((s) => [
                                      // Station Info
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _statusColor(s.status).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.ev_station, size: 14, color: _statusColor(s.status)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text(s.address, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ]),
                                      // City
                                      Text(s.city ?? '—', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      // Status
                                      StatusBadge(status: s.status),
                                      // Slots Indicator
                                      _buildSlotIndicator(s),
                                      // Batteries
                                      Text('${s.availableBatteries}', style: TextStyle(color: s.availableBatteries > 0 ? Colors.green : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13)),
                                      // Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _actionBtn(Icons.edit_outlined, Colors.blue, () => _onEdit(s)),
                                          _actionBtn(Icons.visibility_outlined, Colors.white54, () => _onStationSelected(s)),
                                          _actionBtn(Icons.delete_outline, Colors.redAccent, () => _onDelete(s)),
                                        ],
                                      ),
                                    ]).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                  ),
                ),
              ],
            ),
          ),

          // Detail Panel (Desktop only)
          if (!isMobile && _selectedStation != null)
            Expanded(
              flex: 1,
              child: _buildDetailPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<Station> stations) {
    final total = stations.length;
    final operational = stations.where((s) => s.status.toLowerCase() == 'operational' || s.status.toLowerCase() == 'active').length;
    final maintenance = stations.where((s) => s.status.toLowerCase() == 'maintenance').length;
    final offline = stations.where((s) => s.status.toLowerCase() == 'offline' || s.status.toLowerCase() == 'inactive').length;

    return Row(
      children: [
        _statCard('Total', total.toString(), Icons.ev_station, Colors.blue),
        const SizedBox(width: 16),
        _statCard('Operational', operational.toString(), Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 16),
        _statCard('Maintenance', maintenance.toString(), Icons.build_outlined, Colors.orange),
        const SizedBox(width: 16),
        _statCard('Offline', offline.toString(), Icons.cloud_off, Colors.red),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotIndicator(Station s) {
    final pct = s.totalSlots > 0 ? (s.totalSlots - s.availableSlots) / s.totalSlots : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(_statusColor(s.status)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${s.totalSlots - s.availableSlots}/${s.totalSlots}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: _filterStatus,
        hint: const Text('All Status', style: TextStyle(color: Colors.white54, fontSize: 13)),
        dropdownColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.filter_list, color: Colors.white54, size: 16),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: const [
          DropdownMenuItem(value: null, child: Text('All Status')),
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        ],
        onChanged: (v) => setState(() => _filterStatus = v),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final station = _selectedStation!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(station.address, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedStation = null),
                  icon: const Icon(Icons.close, color: Colors.white38),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  CameraPlayer(station: station),
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  _buildDetailStatsGrid(station),
                  const SizedBox(height: 24),

                  // Actions
                  _detailActionBtn('Performance Stats', Icons.bar_chart, Colors.purple, () => context.go('/stations/performance/${station.id}/${Uri.encodeComponent(station.name)}')),
                  _detailActionBtn('Operating Hours', Icons.schedule, Colors.orange, () => _showOperationsSheet(station)),
                  _detailActionBtn('Active Rentals', Icons.list_alt, Colors.teal, () => _showRentalsSheet(station)),
                  _detailActionBtn('Technical Specs', Icons.electrical_services, Colors.blue, () => showStationSpecsDialog(context, station)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatsGrid(Station station) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _detailInfoChip('${station.totalSlots} Total Slots', Colors.blue),
        _detailInfoChip('${station.availableBatteries} Batteries', Colors.green),
        _detailInfoChip('${station.availableSlots} Empty Slots', Colors.orange),
        _statusBadge(station),
      ],
    );
  }

  Widget _statusBadge(Station station) {
    final statusObj = StationHours.fromJsonString(station.openingHours).getStatus(is24x7: station.is24x7);
    final String label;
    final Color color;
    
    if (station.status.toLowerCase() == 'maintenance') {
      label = 'MAINTENANCE';
      color = Colors.orange;
    } else if (station.status.toLowerCase() == 'inactive') {
      label = 'INACTIVE';
      color = Colors.grey;
    } else {
      label = statusObj == StationStatus.open ? 'OPEN' : (statusObj == StationStatus.closingSoon ? 'CLOSING SOON' : 'CLOSED');
      color = statusObj == StationStatus.open ? Colors.green : (statusObj == StationStatus.closingSoon ? Colors.orange : Colors.red);
    }

    return infoChip(label, color);
  }

  Widget _detailInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showRentalsSheet(Station station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Rentals', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ActiveRentalsGrid(stationId: station.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOperationsSheet(Station station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Station Operations', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OperatingHoursSettingsView(station: station),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'operational': return Colors.green;
      case 'maintenance': return Colors.orange;
      case 'inactive':
      case 'offline': return Colors.red;
      default: return Colors.blue;
    }
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => Tooltip(
    message: 'Action',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: color),
      ),
    ),
  );
}

Widget infoChip(String label, Color color) {
  return Container(
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
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
