import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/station.dart';
import '../data/models/maintenance_model.dart';
import '../data/repositories/station_repository.dart';

class StationMaintenanceView extends StatefulWidget {
  const StationMaintenanceView({super.key});

  @override
  State<StationMaintenanceView> createState() => _StationMaintenanceViewState();
}

class _StationMaintenanceViewState extends State<StationMaintenanceView> {
  final StationRepository _repository = StationRepository();
  List<MaintenanceRecord> _records = [];
  MaintenanceStats _stats = const MaintenanceStats(totalRecords: 0, completed: 0, scheduled: 0, inProgress: 0, totalCost: 0.0, stationsInMaintenance: 0);
  List<Station> _stations = [];
  bool _isLoading = true;
  String? _filterStatus;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getMaintenanceRecords(status: _filterStatus),
        _repository.getMaintenanceStats(),
        _repository.getStations(),
      ]);

      final recordsData = results[0] as Map<String, dynamic>;
      final stats = results[1] as MaintenanceStats;
      final stationsData = results[2] as Map<String, dynamic>;

      setState(() {
        _records = recordsData['records'] as List<MaintenanceRecord>;
        _totalCount = recordsData['total_count'] as int;
        _stats = stats;
        _stations = stationsData['stations'] as List<Station>;
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
            title: 'Maintenance Management',
            subtitle: 'Track maintenance schedules, records, costs, and station health status.',
            actionButton: Row(mainAxisSize: MainAxisSize.min, children: [
              _buildRefreshButton(),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats
          Row(children: [
            _buildStatCard('Total Records', _stats.totalRecords.toString(), Icons.assignment_outlined, const Color(0xFF3B82F6)),
            const SizedBox(width: 16),
            _buildStatCard('Completed', _stats.completed.toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
            const SizedBox(width: 16),
            _buildStatCard('Scheduled', _stats.scheduled.toString(), Icons.schedule_outlined, const Color(0xFFF59E0B)),
            const SizedBox(width: 16),
            _buildStatCard('In Progress', _stats.inProgress.toString(), Icons.engineering_outlined, const Color(0xFF8B5CF6)),
            const SizedBox(width: 16),
            _buildStatCard('Total Cost', '₹${NumberFormat('#,##0').format(_stats.totalCost)}', Icons.currency_rupee_outlined, const Color(0xFFEC4899)),
            const SizedBox(width: 16),
            _buildStatCard('In Maint.', _stats.stationsInMaintenance.toString(), Icons.build_outlined, const Color(0xFFEF4444)),
          ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Data Table
          AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Text('$_totalCount records', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                        const Spacer(),
                        _buildStatusFilter(),
                      ]),
                    ),
                    _records.isEmpty
                        ? SizedBox(height: 200, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.build_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('No maintenance records', style: GoogleFonts.inter(color: Colors.white54)),
                          ])))
                        : AdvancedTable(
                            columns: const ['Station', 'Type', 'Description', 'Cost', 'Status', 'Date', 'Actions'],
                            rows: _records.map((r) {
                              return [
                                Text(r.entityName ?? 'Station #${r.entityId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                                _typeBadge(r.maintenanceType),
                                Expanded(child: Text(r.description, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                Text('₹${NumberFormat('#,##0').format(r.cost)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                StatusBadge(status: r.status),
                                Text(r.performedAt != null ? DateFormat('MMM d, y').format(r.performedAt!) : '—', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz, size: 20, color: Colors.white54),
                                    color: const Color(0xFF1E293B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (action) => _handleStatusUpdate(r, action),
                                    itemBuilder: (ctx) => [
                                      if (r.status != 'completed') _popupItem('completed', Icons.check_circle_outline, 'Mark Completed', const Color(0xFF22C55E)),
                                      if (r.status == 'scheduled') _popupItem('in_progress', Icons.play_circle_outline, 'Start Work', const Color(0xFF3B82F6)),
                                      _popupItem('view', Icons.visibility_outlined, 'View Details', Colors.white70),
                                    ],
                                  ),
                                ]),
                              ];
                            }).toList(),
                          ),
                  ]),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 9), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

  Widget _buildStatusFilter() => DropdownButtonHideUnderline(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
    child: DropdownButton<String?>(
      value: _filterStatus, hint: const Text('All Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
      dropdownColor: const Color(0xFF1E293B), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
      style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Status')),
        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
      ],
      onChanged: (v) { setState(() => _filterStatus = v); _loadData(); },
    ),
  ));

  Widget _typeBadge(String type) {
    Color color;
    switch (type) {
      case 'preventive': color = const Color(0xFF3B82F6); break;
      case 'corrective': color = const Color(0xFFF59E0B); break;
      case 'emergency': color = const Color(0xFFEF4444); break;
      default: color = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(type.substring(0, 1).toUpperCase() + type.substring(1), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String text, Color color) => PopupMenuItem(
    value: value,
    child: Row(children: [
      Icon(icon, size: 18, color: color), const SizedBox(width: 10),
      Text(text, style: TextStyle(color: color, fontSize: 13)),
    ]),
  );

  void _handleStatusUpdate(MaintenanceRecord record, String action) async {
    if (action == 'view') {
      _showRecordDetail(record);
      return;
    }
    final ok = await _repository.updateMaintenanceStatus(record.id, action);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $action'), backgroundColor: Colors.green));
      _loadData();
    }
  }

  void _showRecordDetail(MaintenanceRecord r) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.build, color: Color(0xFF3B82F6), size: 22), const SizedBox(width: 12),
        Expanded(child: Text('Maintenance Record #${r.id}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
        StatusBadge(status: r.status),
      ]),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _dRow('Station', r.entityName ?? 'Station #${r.entityId}'),
        _dRow('Type', r.maintenanceTypeDisplay),
        _dRow('Description', r.description),
        _dRow('Cost', '₹${NumberFormat('#,##0').format(r.cost)}'),
        _dRow('Status', r.status.toUpperCase()),
        _dRow('Date', r.performedAt != null ? DateFormat('MMM d, yyyy HH:mm').format(r.performedAt!) : '—'),
        if (r.partsReplaced != null) _dRow('Parts Replaced', r.partsReplaced!),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white54)))],
    ));
  }

  Widget _dRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 120, child: Text(l, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13))),
    Expanded(child: Text(v, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
  ]));

  InputDecoration _inputDeco(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: const Color(0xFF0F172A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none));

  void _showCreateDialog() {
    int? selectedStationId;
    String maintenanceType = 'preventive';
    String status = 'scheduled';
    final descC = TextEditingController();
    final costC = TextEditingController(text: '0');
    bool submitting = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Create Maintenance Record', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          value: selectedStationId,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('Station *'),
          items: _stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
          onChanged: (v) => ss(() => selectedStationId = v),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: maintenanceType, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('Type'),
          items: const [
            DropdownMenuItem(value: 'preventive', child: Text('Preventive')),
            DropdownMenuItem(value: 'corrective', child: Text('Corrective')),
            DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
          ],
          onChanged: (v) => ss(() => maintenanceType = v!),
        ),
        const SizedBox(height: 14),
        TextField(controller: descC, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Description *')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextField(controller: costC, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Cost (₹)'))),
          const SizedBox(width: 14),
          Expanded(child: DropdownButtonFormField<String>(
            value: status, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white),
            decoration: _inputDeco('Status'),
            items: const [
              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (v) => ss(() => status = v!),
          )),
        ]),
      ])),
      actions: [
        TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: submitting ? null : () async {
            if (selectedStationId == null || descC.text.isEmpty) return;
            ss(() => submitting = true);
            final ok = await _repository.createMaintenanceRecord(
              entityId: selectedStationId!, description: descC.text,
              maintenanceType: maintenanceType, cost: double.tryParse(costC.text) ?? 0, status: status,
            );
            if (ctx.mounted) Navigator.pop(ctx);
            if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maintenance record created!'), backgroundColor: Colors.green)); _loadData(); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    )));
  }
}
