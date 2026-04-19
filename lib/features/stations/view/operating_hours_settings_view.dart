import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/station.dart';
import '../data/models/station_hours.dart';
import '../data/providers/stations_provider.dart';

class OperatingHoursSettingsView extends ConsumerStatefulWidget {
  final Station station;

  const OperatingHoursSettingsView({super.key, required this.station});

  @override
  ConsumerState<OperatingHoursSettingsView> createState() =>
      _OperatingHoursSettingsViewState();
}

class _OperatingHoursSettingsViewState
    extends ConsumerState<OperatingHoursSettingsView> {
  late StationHours _hours;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hours = StationHours.fromJsonString(widget.station.openingHours);
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final currentDaySchedule = _hours.schedule[day]!;
    final initialTimeStr = isOpenTime
        ? currentDaySchedule.open
        : currentDaySchedule.close;
    final timeParts = initialTimeStr.split(':');

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        final current = _hours.schedule[day]!;
        _hours.schedule[day] = DaySchedule(
          open: isOpenTime ? newTime : current.open,
          close: isOpenTime ? current.close : newTime,
          isOpen: current.isOpen,
        );
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      final current = _hours.schedule[day]!;
      _hours.schedule[day] = DaySchedule(
        open: current.open,
        close: current.close,
        isOpen: !current.isOpen,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final updatedStation = widget.station.copyWith(
        openingHours: _hours.toJsonString(),
      );

      await ref.read(stationsProvider.notifier).updateStation(updatedStation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operating hours updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating hours: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Operating Hours',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save Changes'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _hours.schedule.keys
                  .map((day) => _buildDayRow(day))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final schedule = _hours.schedule[day]!;
    final displayName = day[0].toUpperCase() + day.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              displayName,
              style: GoogleFonts.inter(
                color: schedule.isOpen ? Colors.white : Colors.white38,
                fontWeight: schedule.isOpen
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Switch(
            value: schedule.isOpen,
            onChanged: (val) => _toggleDay(day),
            activeThumbColor: Colors.blue,
          ),
          
          if (schedule.isOpen) ...[
            _timeButton(schedule.open, () => _selectTime(day, true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('-', style: TextStyle(color: Colors.white30)),
            ),
            _timeButton(schedule.close, () => _selectTime(day, false)),
          ] else
            Text(
              'Closed',
              style: GoogleFonts.inter(
                color: Colors.redAccent.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeButton(String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          time,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
