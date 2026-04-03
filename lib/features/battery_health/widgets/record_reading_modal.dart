// lib/features/battery_health/widgets/record_reading_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/health_repository.dart';
import '../data/models/health_models.dart';

class RecordReadingModal extends ConsumerStatefulWidget {
  final String? batteryId;
  final String? batterySerial;
  final VoidCallback onSuccess;

  const RecordReadingModal({
    super.key,
    this.batteryId,
    this.batterySerial,
    required this.onSuccess,
  });

  @override
  ConsumerState<RecordReadingModal> createState() => _RecordReadingModalState();
}

class _RecordReadingModalState extends ConsumerState<RecordReadingModal> {
  double _healthPct = 85.0;
  final _voltCtrl = TextEditingController(text: '50.0');
  final _tempCtrl = TextEditingController(text: '35.0');
  final _resCtrl = TextEditingController(text: '15.0');
  bool _loading = false;
  String? _error;
  String? _batId;
  String? _batSerial;
  List<HealthBattery> _results = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _batId = widget.batteryId;
    _batSerial = widget.batterySerial;
  }

  @override
  void dispose() {
    _voltCtrl.dispose();
    _tempCtrl.dispose();
    _resCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
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

  Color get _hColor => _healthPct > 80
      ? const Color(0xFF10B981)
      : _healthPct > 50
      ? const Color(0xFFF59E0B)
      : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Record Health Reading',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_batId == null) ...[
              Text(
                'Select Battery',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _searchCtrl,
                onChanged: _search,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
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
              const SizedBox(height: 12),
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
            Row(
              children: [
                Text(
                  'Health %',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_healthPct.toInt()}%',
                  style: GoogleFonts.outfit(
                    color: _hColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _hColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _healthPct,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => setState(() => _healthPct = v),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voltage (V)',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _voltCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: _dec(''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temp (°C)',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _tempCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: _dec(''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resistance (mΩ)',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _resCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: _dec(''),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_healthPct < 50)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Low health — an alert will be auto-created.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading || _batId == null ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
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
                          'Save Reading',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      await ref.read(healthRepositoryProvider).recordSnapshot(_batId!, {
        'health_percentage': _healthPct,
        'voltage': double.tryParse(_voltCtrl.text),
        'temperature': double.tryParse(_tempCtrl.text),
        'internal_resistance': double.tryParse(_resCtrl.text),
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
