// lib/features/battery_health/widgets/schedule_maintenance_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/health_repository.dart';
import '../data/models/health_models.dart';

class ScheduleMaintenanceModal extends ConsumerStatefulWidget {
  final String? batteryId;
  final String? batterySerial;
  final VoidCallback onSuccess;

  const ScheduleMaintenanceModal({
    super.key,
    this.batteryId,
    this.batterySerial,
    required this.onSuccess,
  });

  @override
  ConsumerState<ScheduleMaintenanceModal> createState() => _State();
}

class _State extends ConsumerState<ScheduleMaintenanceModal> {
  String? _batId, _batSerial;
  String _type = 'inspection';
  String _priority = 'medium';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<HealthBattery> _results = [];
  final _searchCtrl = TextEditingController();

  final _types = [
    {
      'key': 'inspection',
      'icon': Icons.search_rounded,
      'label': 'Inspection',
      'color': const Color(0xFF3B82F6),
    },
    {
      'key': 'deep_service',
      'icon': Icons.build_rounded,
      'label': 'Deep Service',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'key': 'calibration',
      'icon': Icons.tune_rounded,
      'label': 'Calibration',
      'color': const Color(0xFFF59E0B),
    },
    {
      'key': 'replacement',
      'icon': Icons.swap_horiz_rounded,
      'label': 'Replacement',
      'color': const Color(0xFFEF4444),
    },
  ];

  final _priorities = [
    {'key': 'low', 'label': 'Low', 'color': const Color(0xFF10B981)},
    {'key': 'medium', 'label': 'Medium', 'color': const Color(0xFFF59E0B)},
    {'key': 'high', 'label': 'High', 'color': const Color(0xFFEF4444)},
    {'key': 'critical', 'label': 'Critical', 'color': const Color(0xFF7F1D1D)},
  ];

  @override
  void initState() {
    super.initState();
    _batId = widget.batteryId;
    _batSerial = widget.batterySerial;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Schedule Maintenance',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Battery selector
              if (_batId == null) ...[
                Text(
                  'Select Battery',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _dec('Type serial...'),
                ),
                if (_results.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _results
                          .map(
                            (b) => ListTile(
                              dense: true,
                              title: Text(
                                b.serialNumber,
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => setState(() {
                                _batId = b.id;
                                _batSerial = b.serialNumber;
                                _results = [];
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.battery_charging_full_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _batSerial ?? _batId!,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.batteryId == null) ...[
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() {
                            _batId = null;
                            _batSerial = null;
                          }),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Maintenance Type Cards
              Text(
                'Maintenance Type',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _types.map((t) {
                  final sel = _type == t['key'];
                  final c = t['color'] as Color;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t['key'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withValues(alpha: 0.12)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? c.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.06),
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t['icon'] as IconData,
                                color: sel ? c : Colors.white38,
                                size: 22,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t['label'] as String,
                                style: TextStyle(
                                  color: sel ? c : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Priority Pills
              Text(
                'Priority',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final sel = _priority == p['key'];
                  final c = p['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: sel,
                      label: Text(p['label'] as String),
                      selectedColor: c.withValues(alpha: 0.15),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: sel ? c : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: sel
                            ? c.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) =>
                          setState(() => _priority = p['key'] as String),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Date Picker
              Text(
                'Scheduled Date',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white38,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Text(
                'Notes (optional)',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: _dec('Add notes...'),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: const Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading || _batId == null ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Schedule',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
    filled: true,
    fillColor: const Color(0xFF0F172A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );

  void _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    try {
      final r = await ref
          .read(healthRepositoryProvider)
          .getBatteries(search: q, limit: 5);
      setState(() => _results = r);
    } catch (_) {}
  }

  void _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(healthRepositoryProvider).scheduleMaintenance({
        'battery_id': _batId,
        'scheduled_date': _date.toIso8601String(),
        'maintenance_type': _type,
        'priority': _priority,
        'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed: $e';
        _loading = false;
      });
    }
  }
}
