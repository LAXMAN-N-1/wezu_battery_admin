import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../data/models/battery.dart';
import '../data/repositories/inventory_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class BatteryFormDrawer extends StatefulWidget {
  final Battery? battery;
  final VoidCallback? onSaved;
  const BatteryFormDrawer({super.key, this.battery, this.onSaved});

  @override
  State<BatteryFormDrawer> createState() => _BatteryFormDrawerState();
}

class _BatteryFormDrawerState extends SafeState<BatteryFormDrawer> {
  final InventoryRepository _repository = InventoryRepository();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final int _currentSection = 0;

  bool get isEditing => widget.battery != null;

  // Controllers
  late TextEditingController _serialController;
  late TextEditingController _manufacturerController;
  late TextEditingController _notesController;
  String _status = 'available';
  String _locationType = 'warehouse';
  String _batteryType = '48V/30Ah';
  double _healthPercentage = 100.0;
  int _warrantyMonths = 24;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  DateTime? _manufactureDate;

  @override
  void initState() {
    super.initState();
    final b = widget.battery;
    _serialController = TextEditingController(text: b?.serialNumber ?? _generateSerial());
    _manufacturerController = TextEditingController(text: b?.manufacturer ?? '');
    _notesController = TextEditingController(text: b?.notes ?? '');
    if (b != null) {
      _status = b.status;
      _locationType = b.locationType;
      _batteryType = b.batteryType ?? '48V/30Ah';
      _healthPercentage = b.healthPercentage;
      _purchaseDate = b.purchaseDate;
      _warrantyExpiry = b.warrantyExpiry;
      _manufactureDate = b.manufactureDate;
    }
  }

  String _generateSerial() {
    final year = DateTime.now().year;
    final rand = Random().nextInt(999).toString().padLeft(3, '0');
    return 'BAT-$year-$rand';
  }

  void _regenerateSerial() {
    setState(() => _serialController.text = _generateSerial());
  }

  void _updateWarrantyFromMonths() {
    if (_purchaseDate != null) {
      setState(() {
        _warrantyExpiry = DateTime(_purchaseDate!.year, _purchaseDate!.month + _warrantyMonths, _purchaseDate!.day);
      });
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _manufacturerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final data = {
        'serial_number': _serialController.text,
        'status': _status,
        'location_type': _locationType,
        'battery_type': _batteryType,
        'health_percentage': _healthPercentage,
        'manufacturer': _manufacturerController.text.isEmpty ? null : _manufacturerController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'purchase_date': _purchaseDate?.toIso8601String(),
        'warranty_expiry': _warrantyExpiry?.toIso8601String(),
        'manufacture_date': _manufactureDate?.toIso8601String(),
      };
      data.removeWhere((key, value) => value == null);

      if (isEditing) {
        await _repository.updateBattery(widget.battery!.id, data);
      } else {
        await _repository.createBattery(data);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Battery updated' : 'Battery registered'), backgroundColor: const Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = ['Identity', 'Location & Type', 'Health & Lifecycle'];
    return Container(
      width: 480,
      color: const Color(0xFF0F172A),
      child: Form(
        key: _formKey,
        child: Column(children: [
          _buildHeader(),
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(children: List.generate(sections.length, (i) {
              final isActive = i == _currentSection;
              final isDone = i < _currentSection;
              return Expanded(child: Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? const Color(0xFF22C55E) : (isActive ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(sections[i], style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.white30, fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ), overflow: TextOverflow.ellipsis)),
                if (i < sections.length - 1)
                  Expanded(child: Container(height: 1, color: isDone ? const Color(0xFF22C55E).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04))),
              ]));
            })),
          ),
          // Sections
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildIdentitySection(),
                const SizedBox(height: 24),
                _buildLocationSection(),
                const SizedBox(height: 24),
                _buildHealthSection(),
              ]),
            ),
          ),
          _buildFooter(),
        ]),
      ),
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(isEditing ? Icons.edit : Icons.add_circle_outline, color: const Color(0xFF3B82F6), size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEditing ? 'Edit Battery' : 'Register New Battery', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(isEditing ? 'Update battery details' : 'Add a new battery to the fleet', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ]),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white38)),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }

  // =========================================================================
  // SECTION 1: IDENTITY
  // =========================================================================
  Widget _buildIdentitySection() {
    return _section('Identity', Icons.badge, [
      // Serial with auto-generate
      Row(children: [
        Expanded(child: _textField(_serialController, 'Serial Number', isMonospace: true, icon: Icons.qr_code, enabled: !isEditing)),
        if (!isEditing) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: _regenerateSerial,
            icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 20),
            tooltip: 'Regenerate serial',
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
          ),
        ],
      ]),
      const SizedBox(height: 14),
      _textField(_manufacturerController, 'Manufacturer', icon: Icons.factory),
      const SizedBox(height: 14),
      _dropdown('Battery Type', _batteryType, ['48V/30Ah', '60V/40Ah', '72V/50Ah'], (v) => setState(() => _batteryType = v!)),
    ]);
  }

  // =========================================================================
  // SECTION 2: LOCATION
  // =========================================================================
  Widget _buildLocationSection() {
    return _section('Location & Type', Icons.location_on, [
      _dropdown('Status', _status, ['available', 'rented', 'maintenance', 'retired'], (v) => setState(() => _status = v!)),
      const SizedBox(height: 14),
      _dropdown('Location Type', _locationType, ['warehouse', 'station', 'service_center', 'recycling'], (v) => setState(() => _locationType = v!)),
    ]);
  }

  // =========================================================================
  // SECTION 3: HEALTH & LIFECYCLE
  // =========================================================================
  Widget _buildHealthSection() {
    final healthColor = _healthPercentage > 80 ? const Color(0xFF22C55E) : (_healthPercentage > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    return _section('Health & Lifecycle', Icons.favorite, [
      // Health slider
      const Text('Initial Health', style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: healthColor,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
              thumbColor: healthColor,
              overlayColor: healthColor.withValues(alpha: 0.1),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _healthPercentage,
              min: 0, max: 100,
              divisions: 100,
              onChanged: (v) => setState(() => _healthPercentage = v),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: healthColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${_healthPercentage.toInt()}%', style: TextStyle(color: healthColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ]),
      const SizedBox(height: 14),

      // Date pickers
      _datePicker('Manufacture Date', _manufactureDate, (d) => setState(() => _manufactureDate = d)),
      const SizedBox(height: 14),
      _datePicker('Purchase Date', _purchaseDate, (d) {
        setState(() => _purchaseDate = d);
        _updateWarrantyFromMonths();
      }),
      const SizedBox(height: 14),

      // Warranty duration
      const Text('Warranty Period', style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [12, 24, 36].map((m) {
        final isActive = _warrantyMonths == m;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () { setState(() => _warrantyMonths = m); _updateWarrantyFromMonths(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isActive ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text('$m months', style: TextStyle(
                color: isActive ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.5),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, fontSize: 13,
              )),
            ),
          ),
        );
      }).toList()),
      if (_warrantyExpiry != null) ...[
        const SizedBox(height: 6),
        Text('Expires: ${DateFormat('dd MMM yyyy').format(_warrantyExpiry!)}', style: const TextStyle(color: Colors.white30, fontSize: 12)),
      ],
      const SizedBox(height: 14),

      // Notes
      const Text('Notes', style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 3,
        decoration: _inputDecoration('Add internal notes...', null),
      ),
    ]);
  }

  // =========================================================================
  // FOOTER
  // =========================================================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(isEditing ? 'Save Changes' : 'Register Battery', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
    );
  }

  // =========================================================================
  // WIDGETS
  // =========================================================================
  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3)),
      ]),
      const SizedBox(height: 14),
      ...children,
    ]);
  }

  Widget _textField(TextEditingController controller, String label, {bool isMonospace = false, IconData? icon, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: isMonospace
          ? GoogleFonts.firaCode(color: Colors.white, fontSize: 14)
          : const TextStyle(color: Colors.white, fontSize: 14),
      validator: label.contains('Serial') ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.25)) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 13), border: InputBorder.none),
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30, size: 20),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, ValueChanged<DateTime> onSelected) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: Color(0xFF3B82F6), surface: Color(0xFF1E293B)),
            ),
            child: child!,
          ),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value != null ? DateFormat('dd MMM yyyy').format(value) : label,
              style: TextStyle(color: value != null ? Colors.white : Colors.white38, fontSize: 14),
            ),
          ),
          if (value != null) Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.2)),
        ]),
      ),
    );
  }
}
