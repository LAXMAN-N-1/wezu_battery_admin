import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/station.dart';
import '../data/repositories/station_repository.dart';

class StationsView extends StatefulWidget {
  const StationsView({super.key});

  @override
  State<StationsView> createState() => _StationsViewState();
}

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
        _repository.getStationsPaginated(
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => Tooltip(
        message: 'Action',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );

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
            final ok = await _repository.updateStationData(s.id, {
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _repository.deleteStationBoolean(s.id);
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
