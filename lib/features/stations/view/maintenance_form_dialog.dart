import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/maintenance_event.dart';
import '../data/providers/stations_provider.dart';
import '../data/providers/maintenance_provider.dart';
import 'package:rrule/rrule.dart';

class MaintenanceFormDialog extends ConsumerStatefulWidget {
  final MaintenanceEvent? initialEvent;
  const MaintenanceFormDialog({super.key, this.initialEvent});

  @override
  ConsumerState<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends ConsumerState<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _crewController;
  
  int? _selectedStationId;
  String? _selectedStationName;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 2));
  MaintenanceType _selectedType = MaintenanceType.routine;
  MaintenanceStatus _selectedStatus = MaintenanceStatus.scheduled;
  
  String _recurrence = 'none'; // none, weekly, monthly, quarterly

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialEvent?.title ?? '');
    _descController = TextEditingController(text: widget.initialEvent?.description ?? '');
    _crewController = TextEditingController(text: widget.initialEvent?.assignedCrew ?? '');
    
    if (widget.initialEvent != null) {
      _selectedStationId = widget.initialEvent!.stationId;
      _selectedStationName = widget.initialEvent!.stationName;
      _startDate = widget.initialEvent!.startTime;
      _endDate = widget.initialEvent!.endTime;
      _selectedType = widget.initialEvent!.type;
      _selectedStatus = widget.initialEvent!.status;
      
      if (widget.initialEvent!.recurrenceRule != null) {
        if (widget.initialEvent!.recurrenceRule!.contains('WEEKLY')) {
          _recurrence = 'weekly';
        } else if (widget.initialEvent!.recurrenceRule!.contains('MONTHLY')) {
          _recurrence = 'monthly';
        } else if (widget.initialEvent!.recurrenceRule!.contains('INTERVAL=3')) {
          _recurrence = 'quarterly';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.initialEvent == null ? 'Schedule Maintenance' : 'Edit Maintenance',
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Station Selection
                stationsAsync.when(
                  data: (stations) => DropdownButtonFormField<int>(
                    initialValue: _selectedStationId,
                    decoration: _inputDecoration('Select Station', Icons.ev_station),
                    dropdownColor: const Color(0xFF1E293B),
                    items: stations.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStationId = val;
                        _selectedStationName = stations.firstWhere((s) => s.id == val).name;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a station' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading stations: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Task Title', Icons.title),
                  validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white70),
                  decoration: _inputDecoration('Description', Icons.description),
                ),
                const SizedBox(height: 16),

                // Using Column instead of Row to prevent horizontal overflow on smaller devices
                DropdownButtonFormField<MaintenanceType>(
                  initialValue: _selectedType,
                  decoration: _inputDecoration('Type', Icons.category),
                  dropdownColor: const Color(0xFF1E293B),
                  items: MaintenanceType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MaintenanceStatus>(
                  initialValue: _selectedStatus,
                  decoration: _inputDecoration('Status', Icons.info_outline),
                  dropdownColor: const Color(0xFF1E293B),
                  items: MaintenanceStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
                const SizedBox(height: 16),

                // Date/Time Selection
                _buildDateTimeTile('Start', _startDate, (dt) => setState(() => _startDate = dt)),
                const SizedBox(height: 8),
                _buildDateTimeTile('End', _endDate, (dt) => setState(() => _endDate = dt)),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _crewController,
                   style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Assigned Crew / Technician', Icons.engineering),
                ),
                const SizedBox(height: 24),

                Text('Recurrence', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    _recurrenceChip('none', 'None'),
                    _recurrenceChip('weekly', 'Weekly'),
                    _recurrenceChip('monthly', 'Monthly'),
                    _recurrenceChip('quarterly', 'Quarterly'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saveEvent,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Save Event'),
        ),
      ],
    );
  }

  Widget _buildDateTimeTile(String label, DateTime dt, ValueChanged<DateTime> onChanged) {
    final df = DateFormat('MMM dd, yyyy  HH:mm');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: dt,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null && mounted) {
             final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(dt));
             if (time != null) {
                onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
             }
          }
        },
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const Spacer(),
            Text(df.format(dt), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.edit_calendar, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _recurrenceChip(String value, String label) {
    final isSelected = _recurrence == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _recurrence = value);
      },
      backgroundColor: Colors.transparent,
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.white38, fontSize: 12),
      side: BorderSide(color: isSelected ? Colors.blue : Colors.white12),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: Colors.blue),
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
    );
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      String? rrule;
      if (_recurrence != 'none') {
        final frequency = _recurrence == 'weekly' ? Frequency.weekly :
                          (_recurrence == 'monthly' ? Frequency.monthly : Frequency.monthly);
        
        final rule = RecurrenceRule(
          frequency: frequency,
          interval: _recurrence == 'quarterly' ? 3 : 1,
        );
        rrule = rule.toString();
      }

      final event = MaintenanceEvent(
        id: widget.initialEvent?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        stationId: _selectedStationId!,
        stationName: _selectedStationName!,
        title: _titleController.text,
        description: _descController.text,
        startTime: _startDate,
        endTime: _endDate,
        status: _selectedStatus,
        type: _selectedType,
        assignedCrew: _crewController.text,
        recurrenceRule: rrule,
      );

      try {
        if (widget.initialEvent == null) {
          ref.read(maintenanceNotifierProvider.notifier).addEvent(event);
        } else {
          ref.read(maintenanceNotifierProvider.notifier).updateEvent(event);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
