import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
=======
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
>>>>>>> origin/main
import '../data/models/station.dart';
import '../data/models/station_hours.dart';
import '../data/providers/stations_provider.dart';
import 'station_form_view.dart';
import 'station_specs_view.dart';
import 'operating_hours_settings_view.dart';
import '../widgets/active_rentals_grid.dart';
import '../widgets/camera_player.dart';

class StationsView extends ConsumerStatefulWidget {
  const StationsView({super.key});

  @override
  ConsumerState<StationsView> createState() => _StationsViewState();
}

<<<<<<< HEAD
class _StationsViewState extends ConsumerState<StationsView> {
  Station? _selectedStation;

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
      if (_selectedStation == null) {
        return _buildListPanel(stationsAsync);
      }
      return Column(
        children: [
          // Detail Panel on top for mobile
          Flexible(
            flex: 2,
            child: _buildDetailPanel(),
          ),
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
        // Detail Panel
        Expanded(
          flex: 2, // 66% width
          child: _buildDetailPanel(),
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
                                _buildStationStatusBadge(station),
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

  Widget _buildDetailPanel() {
    if (_selectedStation == null) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ev_station, size: 64, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text(
                'Select a station to view details',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 18,
                ),
              ),
=======
class _StationsViewState extends State<StationsView> {
  final StationRepository _repository = StationRepository();
  List<Station> _stations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterStatus;
  int _totalCount = 0;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getStations(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          status: _filterStatus,
        ),
        _repository.getStationStats(),
      ]);

      final stationsData = results[0] as Map<String, dynamic>;
      final statsData = results[1] as Map<String, dynamic>;

      setState(() {
        _stations = stationsData['stations'] as List<Station>;
        _totalCount = stationsData['total_count'] as int;
        _stats = statsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'All Stations',
            subtitle: 'Manage your station network — view, create, edit, and monitor station health.',
            actionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: const Icon(Icons.add_location_alt, size: 18),
                  label: const Text('Add Station'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            searchField: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) { _searchQuery = v; _loadData(); },
              decoration: InputDecoration(
                hintText: 'Search by name, address, city...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats
          Row(
            children: [
              _buildStatCard('Total', (_stats['total_stations'] ?? _totalCount).toString(), Icons.ev_station_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Operational', (_stats['operational'] ?? 0).toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildStatCard('Maintenance', (_stats['maintenance'] ?? 0).toString(), Icons.build_outlined, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildStatCard('Offline', (_stats['offline'] ?? 0).toString(), Icons.cloud_off_outlined, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildStatCard('Avg Rating', (_stats['avg_rating'] ?? 0.0).toStringAsFixed(1), Icons.star_outline, const Color(0xFF8B5CF6)),
              const Spacer(),
              _buildFilterDropdown(),
>>>>>>> origin/main
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Data Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Text('$_totalCount stations found', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                        ]),
                      ),
                      AdvancedTable(
                        columns: const ['Station', 'City', 'Status', 'Slots', 'Batteries', 'Rating', 'Type', 'Actions'],
                        rows: _stations.map((s) {
                          return [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _statusColor(s.status).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.ev_station, size: 16, color: _statusColor(s.status)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  Text(s.address, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                                ],
                              )),
                            ]),
                            Text(s.city ?? '—', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            StatusBadge(status: s.status),
                            _slotIndicator(s),
                            Text('${s.availableBatteries}', style: TextStyle(color: s.availableBatteries > 0 ? const Color(0xFF22C55E) : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13)),
                            _ratingWidget(s.rating),
                            StatusBadge(status: s.stationType),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              _actionBtn(Icons.edit_outlined, const Color(0xFF3B82F6), () => _showEditDialog(s)),
                              _actionBtn(Icons.visibility_outlined, Colors.white54, () => _showDetailDialog(s)),
                              _actionBtn(Icons.delete_outline, const Color(0xFFEF4444), () => _confirmDelete(s)),
                            ]),
                          ];
                        }).toList(),
                      ),
                    ],
                  ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() => Container(
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white70, size: 20), onPressed: _loadData, tooltip: 'Refresh'),
  );

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Expanded(
    child: AdvancedCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

  Widget _buildFilterDropdown() => DropdownButtonHideUnderline(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: DropdownButton<String?>(
      value: _filterStatus, hint: const Text('All Status', style: TextStyle(color: Colors.white70, fontSize: 13)),
      dropdownColor: const Color(0xFF1E293B), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Status')),
        DropdownMenuItem(value: 'OPERATIONAL', child: Text('Operational')),
        DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
        DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')),
        DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
        DropdownMenuItem(value: 'ERROR', child: Text('Error')),
      ],
      onChanged: (v) { setState(() => _filterStatus = v); _loadData(); },
    ),
  ));

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

  Widget _slotIndicator(Station s) {
    final used = s.totalSlots - s.availableSlots;
    final pct = s.totalSlots > 0 ? used / s.totalSlots : 0.0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 40, height: 6, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(_statusColor(s.status))))),
      const SizedBox(width: 6),
      Text('$used/${s.totalSlots}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _ratingWidget(double rating) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.star, size: 14, color: rating > 0 ? const Color(0xFFF59E0B) : Colors.white24),
    const SizedBox(width: 3),
    Text(rating.toStringAsFixed(1), style: TextStyle(color: rating > 0 ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => Tooltip(message: '', child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color))));

  InputDecoration _inputDeco(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: const Color(0xFF0F172A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none));

  void _showCreateDialog() {
    final nameC = TextEditingController(), addrC = TextEditingController(), cityC = TextEditingController();
    final latC = TextEditingController(), lngC = TextEditingController(), slotsC = TextEditingController(text: '10');
    final phoneC = TextEditingController(), powerC = TextEditingController();
    bool submitting = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Add New Station', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Station Name *')),
        const SizedBox(height: 12),
        TextField(controller: addrC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Address *')),
        const SizedBox(height: 12),
        TextField(controller: cityC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('City')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: latC, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: _inputDeco('Latitude *'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: lngC, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: _inputDeco('Longitude *'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: slotsC, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: _inputDeco('Total Slots'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: powerC, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: _inputDeco('Power (kW)'))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: phoneC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Contact Phone')),
      ]))),
      actions: [
        TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: submitting ? null : () async {
            if (nameC.text.isEmpty || addrC.text.isEmpty || latC.text.isEmpty || lngC.text.isEmpty) return;
            ss(() => submitting = true);
            final ok = await _repository.createStation(
              name: nameC.text, address: addrC.text, city: cityC.text.isNotEmpty ? cityC.text : null,
              latitude: double.tryParse(latC.text) ?? 0, longitude: double.tryParse(lngC.text) ?? 0,
              totalSlots: int.tryParse(slotsC.text) ?? 0, powerRatingKw: double.tryParse(powerC.text),
              contactPhone: phoneC.text.isNotEmpty ? phoneC.text : null,
            );
            if (ctx.mounted) Navigator.pop(ctx);
            if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station created!'), backgroundColor: Colors.green)); _loadData(); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create', style: TextStyle(color: Colors.white)),
        ),
<<<<<<< HEAD
      );
    }

    return Container(
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CameraPlayer(station: _selectedStation!),
            const SizedBox(height: 24),
            _buildStationDetailCard(_selectedStation!),
          ],
        ),
      ),
    );
  }

  Widget _buildStationDetailCard(Station station) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                      station.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      station.address,
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
              IconButton(
                onPressed: () => setState(() => _selectedStation = null),
                icon: const Icon(Icons.close, color: Colors.white38, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              infoChip('${station.totalSlots} Slots', Colors.blue),
              infoChip('${station.availableBatteries} Bats', Colors.green),
              _buildStationStatusBadge(station),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRentalsSheet(context, station),
                  icon: const Icon(Icons.list_alt, size: 14),
                  label: const Text('Rentals', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showOperationsSheet(context, station),
                  icon: const Icon(Icons.settings_remote, size: 14),
                  label: const Text('Ops', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/stations/performance/${station.id}/${Uri.encodeComponent(station.name)}'),
                  icon: const Icon(Icons.bar_chart, size: 14),
                  label: const Text('Stats', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showStationSpecsSheet(context, station),
                  icon: const Icon(Icons.electrical_services, size: 14),
                  label: const Text('Specs', style: TextStyle(fontSize: 12)),
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
    );
  }

  void _showRentalsSheet(BuildContext context, Station station) {
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
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Rentals',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ActiveRentalsGrid(stationId: station.id),
            ],
          ),
        ),
      ),
    );
  }

  void _showOperationsSheet(BuildContext context, Station station) {
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
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Station Operations',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 500, // Fixed height for constraints
                child: OperatingHoursSettingsView(station: station),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationStatusBadge(Station station) {
    final hours = StationHours.fromJsonString(station.openingHours);
    final status = hours.getStatus();
    
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case StationStatus.open:
        color = const Color(0xFF22C55E); // green
        icon = Icons.check_circle_outline;
        label = 'Open Now';
        break;
      case StationStatus.closingSoon:
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        label = 'Closing Soon';
        break;
      case StationStatus.closed:
        color = const Color(0xFFEF4444); // red
        icon = Icons.cancel_outlined;
        label = 'Closed';
        break;
    }

    // If backend status is maintenance, override
    if (station.status.toLowerCase() == 'maintenance') {
      color = const Color(0xFFF59E0B);
      icon = Icons.construction_outlined;
      label = 'Maintenance';
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
=======
      ],
    )));
  }

  void _showEditDialog(Station s) {
    final nameC = TextEditingController(text: s.name), addrC = TextEditingController(text: s.address), cityC = TextEditingController(text: s.city ?? '');
    final slotsC = TextEditingController(text: s.totalSlots.toString()), phoneC = TextEditingController(text: s.contactPhone ?? '');
    String selectedStatus = s.status;
    bool submitting = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit: ${s.name}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(width: 450, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Station Name')),
        const SizedBox(height: 12),
        TextField(controller: addrC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Address')),
        const SizedBox(height: 12),
        TextField(controller: cityC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('City')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: selectedStatus, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white), decoration: _inputDeco('Status'),
          items: const [
            DropdownMenuItem(value: 'OPERATIONAL', child: Text('Operational')), DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
            DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')), DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
          ],
          onChanged: (v) => ss(() => selectedStatus = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: slotsC, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: _inputDeco('Total Slots'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: phoneC, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Contact Phone'))),
        ]),
      ]))),
      actions: [
        TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: submitting ? null : () async {
            ss(() => submitting = true);
            final ok = await _repository.updateStation(s.id, {
              'name': nameC.text, 'address': addrC.text, 'city': cityC.text.isNotEmpty ? cityC.text : null,
              'status': selectedStatus, 'total_slots': int.tryParse(slotsC.text),
              'contact_phone': phoneC.text.isNotEmpty ? phoneC.text : null,
            });
            if (ctx.mounted) Navigator.pop(ctx);
            if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station updated!'), backgroundColor: Colors.green)); _loadData(); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes', style: TextStyle(color: Colors.white)),
        ),
      ],
    )));
  }

  void _confirmDelete(Station s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete Station', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 24), const SizedBox(width: 12),
          Expanded(child: Text('Are you sure you want to delete "${s.name}"?\nThis cannot be undone.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13))),
        ]),
>>>>>>> origin/main
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _repository.deleteStation(s.id);
            if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${s.name}" deleted'), backgroundColor: Colors.green)); _loadData(); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showDetailDialog(Station s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _statusColor(s.status).withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(Icons.ev_station, color: _statusColor(s.status), size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(s.address, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ])),
        StatusBadge(status: s.status),
      ]),
      content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _dRow('City', s.city ?? '—'), _dRow('Type', s.stationType.toUpperCase()), _dRow('Total Slots', '${s.totalSlots}'),
        _dRow('Available Batteries', '${s.availableBatteries}'), _dRow('Available Slots', '${s.availableSlots}'),
        _dRow('Power Rating', s.powerRatingKw != null ? '${s.powerRatingKw} kW' : '—'),
        _dRow('Rating', '${s.rating} (${s.totalReviews} reviews)'), _dRow('24x7', s.is24x7 ? 'Yes' : 'No'),
        _dRow('Contact', s.contactPhone ?? '—'), _dRow('Created', DateFormat('MMM d, yyyy').format(s.createdAt)),
        if (s.lastHeartbeat != null) _dRow('Last Heartbeat', DateFormat('MMM d, HH:mm').format(s.lastHeartbeat!)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white54)))],
    ));
  }

  Widget _dRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    SizedBox(width: 140, child: Text(l, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13))),
    Expanded(child: Text(v, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
  ]));
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
