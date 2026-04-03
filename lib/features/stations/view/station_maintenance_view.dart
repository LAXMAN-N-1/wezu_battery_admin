import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/maintenance_model.dart';
import '../data/repositories/maintenance_repository.dart';

class StationMaintenanceView extends StatefulWidget {
  const StationMaintenanceView({super.key});

  @override
  State<StationMaintenanceView> createState() => _StationMaintenanceViewState();
}

class _StationMaintenanceViewState extends State<StationMaintenanceView> {
  final MaintenanceRepository _repository = MaintenanceRepository();
  List<MaintenanceRecord> _records = [];
  List<MaintenanceRecord> _filteredRecords = [];
  MaintenanceStats? _stats;
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await _repository.getAllMaintenanceRecords();
    final stats = await _repository.getStats(records);
    setState(() {
      _records = records;
      _stats = stats;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    _filteredRecords = _records.where((r) {
      if (_statusFilter != 'all' && r.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty &&
          !r.description.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !r.maintenanceType.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Maintenance Schedules',
            subtitle:
                'Manage station maintenance records, schedule new tasks, and track costs.',
            actionButton: ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Schedule Maintenance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 24),

          // Stats Cards
          if (_stats != null)
            Row(
              children: [
                _buildStatCard(
                  'Total Records',
                  '${_stats!.total}',
                  Icons.build_outlined,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Completed',
                  '${_stats!.completed}',
                  Icons.check_circle_outline,
                  const Color(0xFF22C55E),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Scheduled',
                  '${_stats!.scheduled}',
                  Icons.schedule_outlined,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'In Progress',
                  '${_stats!.inProgress}',
                  Icons.engineering_outlined,
                  const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Total Cost',
                  '₹${NumberFormat('#,##0').format(_stats!.totalCost)}',
                  Icons.currency_rupee_outlined,
                  const Color(0xFFEF4444),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _applyFilters();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search by description or type...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ...['all', 'scheduled', 'in_progress', 'completed'].map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _statusFilter == s,
                    label: Text(
                      s == 'all'
                          ? 'All'
                          : s == 'in_progress'
                          ? 'In Progress'
                          : s[0].toUpperCase() + s.substring(1),
                    ),
                    labelStyle: TextStyle(
                      color: _statusFilter == s ? Colors.white : Colors.white54,
                      fontSize: 13,
                    ),
                    selectedColor: const Color(0xFF3B82F6),
                    backgroundColor: const Color(0xFF1E293B),
                    checkmarkColor: Colors.white,
                    onSelected: (_) => setState(() {
                      _statusFilter = s;
                      _applyFilters();
                    }),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 24),

          // Table
          AdvancedCard(
                padding: EdgeInsets.zero,
                child: _isLoading
                    ? const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _filteredRecords.isEmpty
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'No maintenance records found.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : AdvancedTable(
                        columns: const [
                          'ID',
                          'Station',
                          'Type',
                          'Description',
                          'Cost',
                          'Status',
                          'Date',
                          'Actions',
                        ],
                        rows: _filteredRecords
                            .map(
                              (r) => [
                                Text(
                                  '#${r.id}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Station #${r.entityId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: r.maintenanceType == 'preventive'
                                        ? const Color(
                                            0xFF22C55E,
                                          ).withValues(alpha: 0.1)
                                        : const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r.maintenanceType.toUpperCase(),
                                    style: TextStyle(
                                      color: r.maintenanceType == 'preventive'
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    r.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##0').format(r.cost)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _buildStatusBadge(r.status),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(r.performedAt),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                _buildActions(r),
                              ],
                            )
                            .toList(),
                      ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final map = {
      'completed': (const Color(0xFF22C55E), 'Completed'),
      'scheduled': (const Color(0xFFF59E0B), 'Scheduled'),
      'in_progress': (const Color(0xFF3B82F6), 'In Progress'),
    };
    final (color, label) = map[status] ?? (Colors.grey, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(MaintenanceRecord r) {
    if (r.status == 'completed') {
      return const Icon(Icons.check, color: Color(0xFF22C55E), size: 18);
    }
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
      color: const Color(0xFF1E293B),
      onSelected: (value) async {
        final success = await _repository.updateStatus(r.id, value);
        if (success) _loadData();
      },
      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[];
        if (r.status == 'scheduled') {
          items.add(
            const PopupMenuItem(
              value: 'in_progress',
              child: Text('Start Work', style: TextStyle(color: Colors.white)),
            ),
          );
        }
        if (r.status == 'in_progress') {
          items.add(
            const PopupMenuItem(
              value: 'completed',
              child: Text(
                'Mark Completed',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return items;
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final typeCtrl = TextEditingController(text: 'preventive');
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stationCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Maintenance',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new maintenance task for a station.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              _dialogField(
                'Station ID',
                stationCtrl,
                type: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _dialogDropdown('Maintenance Type', typeCtrl, [
                'preventive',
                'corrective',
              ]),
              const SizedBox(height: 16),
              _dialogField('Description', descCtrl, maxLines: 2),
              const SizedBox(height: 16),
              _dialogField(
                'Estimated Cost (₹)',
                costCtrl,
                type: TextInputType.number,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await _repository.createMaintenanceRecord(
                        entityId: int.tryParse(stationCtrl.text) ?? 1,
                        maintenanceType: typeCtrl.text,
                        description: descCtrl.text,
                        cost: double.tryParse(costCtrl.text) ?? 0,
                      );
                      if (!ctx.mounted || !mounted) {
                        return;
                      }
                      if (success) {
                        Navigator.pop(ctx);
                        _loadData();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Maintenance scheduled!'),
                            backgroundColor: Color(0xFF22C55E),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Schedule'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController ctrl, {
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogDropdown(
    String label,
    TextEditingController ctrl,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ctrl.text,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              items: options
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o[0].toUpperCase() + o.substring(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => ctrl.text = v ?? '',
            ),
          ),
        ),
      ],
    );
  }
}
