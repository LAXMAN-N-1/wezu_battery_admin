import 'package:flutter/material.dart';
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
        ],
      ),
    );
  }

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
  }
}
