import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/maintenance_provider.dart';
import '../data/providers/checklist_provider.dart';
import '../data/models/maintenance_event.dart';
import 'maintenance_form_dialog.dart';
import 'maintenance_execution_view.dart';
import 'checklist_template_list_dialog.dart';

class StationMaintenanceView extends ConsumerStatefulWidget {
  const StationMaintenanceView({super.key});

  @override
  ConsumerState<StationMaintenanceView> createState() => _StationMaintenanceViewState();
}

class _StationMaintenanceViewState extends ConsumerState<StationMaintenanceView> {
  CalendarView _currentView = CalendarView.month;
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    final maintenanceAsync = ref.watch(maintenanceNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Maintenance Scheduling',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          _ViewSwitcher(
            currentView: _currentView,
            onChanged: (view) {
              setState(() {
                _currentView = view;
                _calendarController.view = view;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 22),
            onPressed: () => context.push('/stations/maintenance/compliance'),
            tooltip: 'Compliance Dashboard',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1E293B),
            onSelected: (val) {
              if (val == 'report') _generateReport(context);
              if (val == 'templates') _showTemplatesDialog(context);
              if (val == 'refresh') {
                 ref.invalidate(maintenanceNotifierProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.assessment_outlined, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Generate Report', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(Icons.checklist_rtl, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Manage Templates', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('Refresh Data', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: maintenanceAsync.when(
        data: (events) => _buildCalendar(events),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add_task),
        label: const Text('Schedule Maintenance'),
      ),
    );
  }

  Widget _buildCalendar(List<MaintenanceEvent> events) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfCalendar(
          view: _currentView,
          controller: _calendarController,
          dataSource: _MaintenanceDataSource(events),
          headerStyle: CalendarHeaderStyle(
            textStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            dateTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          monthViewSettings: const MonthViewSettings(
            showAgenda: true,
            agendaStyle: AgendaStyle(
              backgroundColor: Color(0xFF1E293B),
              appointmentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
              dayTextStyle: TextStyle(color: Colors.white70, fontSize: 12),
              dateTextStyle: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          selectionDecoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          todayHighlightColor: Colors.blue,
          appointmentBuilder: (context, details) {
            final appointment = details.appointments.first as Appointment;
            final event = appointment.id as MaintenanceEvent;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appointment.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border(left: BorderSide(color: appointment.color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.subject,
                    style: GoogleFonts.inter(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 10,  // Reduced from 12
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (details.bounds.height > 40) ...[
                    const Spacer(),
                    Text(
                      event.stationName,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
          allowDragAndDrop: true,
          onDragEnd: (details) {
            final event = details.appointment as MaintenanceEvent;
            final updated = event.copyWith(
              startTime: details.droppingTime!,
              endTime: details.droppingTime!.add(event.endTime.difference(event.startTime)),
            );
            ref.read(maintenanceNotifierProvider.notifier).updateEvent(updated);
          },
          onTap: (details) {
            if (details.appointments != null && details.appointments!.isNotEmpty) {
               _showEventDetails(context, details.appointments!.first.id as MaintenanceEvent);
            }
          },
        ),
      ),
    );
  }

  void _showTemplatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChecklistTemplateListDialog(),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MaintenanceFormDialog(),
    );
  }

  void _showEventEditDialog(BuildContext context, MaintenanceEvent event) {
    showDialog(
      context: context,
      builder: (context) => MaintenanceFormDialog(initialEvent: event),
    );
  }

  void _showEventDetails(BuildContext context, MaintenanceEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(child: Text(event.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18))),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () {
                Navigator.pop(context);
                _showEventEditDialog(context, event);
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.ev_station, 'Station', event.stationName),
            _detailRow(Icons.category, 'Type', event.type.label),
            _statusBadge(event.status),
            _detailRow(Icons.people, 'Crew', event.assignedCrew ?? 'Unassigned'),
            if (event.recurrenceRule != null)
              _detailRow(Icons.repeat, 'Recurrence', _formatRRule(event.recurrenceRule!)),
            const SizedBox(height: 12),
            Text('Description:', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(event.description, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(maintenanceNotifierProvider.notifier).deleteEvent(event.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (event.status != MaintenanceStatus.completed)
            ElevatedButton(
              onPressed: () async {
                final templates = ref.read(checklistTemplateNotifierProvider).value ?? [];
                // Find matching template or use first as fallback for demo
                final template = templates.firstWhere(
                  (t) => t.maintenanceType == event.type.name,
                  orElse: () => templates.first,
                );
                
                Navigator.pop(context);
                
                // Directly navigate to execution view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaintenanceExecutionView(event: event, template: template),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(event.status == MaintenanceStatus.scheduled ? 'Start Task' : 'Continue Task'),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(MaintenanceStatus status) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(status.label, style: GoogleFonts.inter(color: status.color, fontSize: 12, fontWeight: FontWeight.bold)),
=======
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
>>>>>>> origin/main
        ],
      ),
    );
  }

<<<<<<< HEAD
  String _formatRRule(String rule) {
    if (rule.contains('WEEKLY')) return 'Weekly';
    if (rule.contains('MONTHLY')) {
       if (rule.contains('INTERVAL=3')) return 'Quarterly';
       return 'Monthly';
    }
    return 'Custom';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context) {
    final events = ref.read(maintenanceNotifierProvider).value ?? [];
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No maintenance records available to generate report.')),
      );
      return;
    }

    final completed = events.where((e) => e.status == MaintenanceStatus.completed).length;
    final scheduled = events.where((e) => e.status == MaintenanceStatus.scheduled).length;
    final inProgress = events.where((e) => e.status == MaintenanceStatus.inProgress).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Maintenance Summary Report', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reportRow('Total Records', events.length.toString()),
            _reportRow('Completed', completed.toString()),
            _reportRow('In Progress', inProgress.toString()),
            _reportRow('Scheduled', scheduled.toString()),
            const Divider(color: Colors.white10, height: 24),
            Text('Audit Trail Summary:', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              width: 300,
              child: ListView.builder(
                itemCount: events.length > 5 ? 5 : events.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${events[index].title}: ${events[index].status.label}',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Export CSV (Mock)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MaintenanceDataSource extends CalendarDataSource {
  _MaintenanceDataSource(List<MaintenanceEvent> source) {
    appointments = source.map((event) {
      return Appointment(
        id: event,
        startTime: event.startTime,
        endTime: event.endTime,
        subject: event.title,
        color: event.status.color,
        notes: event.description,
        isAllDay: false,
        recurrenceRule: event.recurrenceRule,
      );
    }).toList();
  }
}

class _ViewSwitcher extends StatelessWidget {
  final CalendarView currentView;
  final ValueChanged<CalendarView> onChanged;

  const _ViewSwitcher({required this.currentView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _viewButton('Month', CalendarView.month),
          _viewButton('Week', CalendarView.week),
          _viewButton('Day', CalendarView.day),
        ],
      ),
    );
  }

  Widget _viewButton(String label, CalendarView view) {
    final isSelected = currentView == view;
    return GestureDetector(
      onTap: () => onChanged(view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
=======
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
>>>>>>> origin/main
  }
}
