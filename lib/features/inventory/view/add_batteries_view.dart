import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/repositories/inventory_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBlue = Color(0xFF3B82F6);
const _kGreen = Color(0xFF22C55E);
const _kBorder = Color(0x10FFFFFF);
const _kBorderFaint = Color(0x08FFFFFF);

const _kBatteryTypes = ['48V/30Ah', '60V/40Ah', '72V/50Ah', '96V/60Ah'];
const _kHealthStatuses = ['good', 'excellent', 'fair', 'poor', 'critical', 'damaged'];
const _kWarrantyMonthOptions = [12, 24, 36, 48];

// ─────────────────────────────────────────────────────────────────────────────
// Root view
// ─────────────────────────────────────────────────────────────────────────────

class AddBatteriesView extends StatefulWidget {
  const AddBatteriesView({super.key});

  @override
  State<AddBatteriesView> createState() => _AddBatteriesViewState();
}

class _AddBatteriesViewState extends State<AddBatteriesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InventoryBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SingleBatteryTab(onSuccess: _onSuccess),
                _BulkBatteriesTab(onSuccess: _onSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSuccess() {
    if (mounted) context.go('/fleet/batteries');
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBlue.withValues(alpha: 0.35)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _kBlue,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.battery_full_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Single Battery'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_to_queue_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Bulk Add'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Central inventory banner
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: _kBlue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.white54, fontSize: 12),
                children: [
                  TextSpan(
                    text: 'Batteries created here land in ',
                    style: TextStyle(color: Colors.white54),
                  ),
                  TextSpan(
                    text: 'Central Inventory',
                    style: TextStyle(color: _kBlue, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: '.  From there, assign them to specific warehouses.  Warehouses then fulfill orders to dealer stations.'),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kBlue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 12, color: _kBlue),
                SizedBox(width: 4),
                Text('Central Inventory', style: TextStyle(color: _kBlue, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE BATTERY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _SingleBatteryTab extends StatefulWidget {
  final VoidCallback onSuccess;
  const _SingleBatteryTab({required this.onSuccess});

  @override
  State<_SingleBatteryTab> createState() => _SingleBatteryTabState();
}

class _SingleBatteryTabState extends State<_SingleBatteryTab> {
  final _repo = InventoryRepository();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Identity
  late final TextEditingController _serialCtrl;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _iotDeviceCtrl;
  late final TextEditingController _skuIdCtrl;
  late final TextEditingController _specIdCtrl;
  String _batteryType = '48V/30Ah';

  // New batteries always land in central inventory as 'available'
  String _healthStatus = 'good';

  // Health & state
  double _healthPct = 100.0;
  double _currentCharge = 100.0;
  double _stateOfHealth = 100.0;
  late final TextEditingController _tempCtrl;

  // Costs & cycles
  late final TextEditingController _purchaseCostCtrl;
  late final TextEditingController _cycleCountCtrl;
  late final TextEditingController _totalCyclesCtrl;
  late final TextEditingController _chargeCyclesCtrl;
  late final TextEditingController _lastMaintenanceCyclesCtrl;

  // Dates
  DateTime? _manufactureDate;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  DateTime? _lastChargedAt;
  DateTime? _lastInspectedAt;
  DateTime? _lastMaintenanceDate;
  int _warrantyMonths = 24;

  // Notes
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _serialCtrl = TextEditingController(text: _generateSerial());
    _manufacturerCtrl = TextEditingController();
    _iotDeviceCtrl = TextEditingController();
    _skuIdCtrl = TextEditingController();
    _specIdCtrl = TextEditingController();
    _tempCtrl = TextEditingController(text: '25.0');
    _purchaseCostCtrl = TextEditingController(text: '0');
    _cycleCountCtrl = TextEditingController(text: '0');
    _totalCyclesCtrl = TextEditingController(text: '0');
    _chargeCyclesCtrl = TextEditingController(text: '0');
    _lastMaintenanceCyclesCtrl = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _serialCtrl, _manufacturerCtrl, _iotDeviceCtrl, _skuIdCtrl, _specIdCtrl,
      _tempCtrl, _purchaseCostCtrl, _cycleCountCtrl, _totalCyclesCtrl,
      _chargeCyclesCtrl, _lastMaintenanceCyclesCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _generateSerial() {
    final year = DateTime.now().year;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'BAT-$year-$rand';
  }

  void _updateWarrantyFromMonths() {
    if (_purchaseDate != null) {
      setState(() {
        _warrantyExpiry = DateTime(
          _purchaseDate!.year,
          _purchaseDate!.month + _warrantyMonths,
          _purchaseDate!.day,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // location_type + location_id intentionally omitted → backend defaults to
      // warehouse with null location_id, which is "central inventory".
      final data = <String, dynamic>{
        'serial_number': _serialCtrl.text.trim().toUpperCase(),
        'battery_type': _batteryType,
        'status': 'available',
        'health_status': _healthStatus,
        'location_type': 'warehouse',
        'health_percentage': _healthPct,
        'current_charge': _currentCharge,
        'state_of_health': _stateOfHealth,
        'temperature_c': double.tryParse(_tempCtrl.text) ?? 25.0,
        'purchase_cost': double.tryParse(_purchaseCostCtrl.text) ?? 0.0,
        'cycle_count': int.tryParse(_cycleCountCtrl.text) ?? 0,
        'total_cycles': int.tryParse(_totalCyclesCtrl.text) ?? 0,
        'charge_cycles': int.tryParse(_chargeCyclesCtrl.text) ?? 0,
        'last_maintenance_cycles': int.tryParse(_lastMaintenanceCyclesCtrl.text) ?? 0,
        if (_manufacturerCtrl.text.trim().isNotEmpty) 'manufacturer': _manufacturerCtrl.text.trim(),
        if (_iotDeviceCtrl.text.trim().isNotEmpty) 'iot_device_id': _iotDeviceCtrl.text.trim(),
        if (_skuIdCtrl.text.trim().isNotEmpty) 'sku_id': int.tryParse(_skuIdCtrl.text.trim()),
        if (_specIdCtrl.text.trim().isNotEmpty) 'spec_id': int.tryParse(_specIdCtrl.text.trim()),
        if (_manufactureDate != null) 'manufacture_date': _manufactureDate!.toIso8601String(),
        if (_purchaseDate != null) 'purchase_date': _purchaseDate!.toIso8601String(),
        if (_warrantyExpiry != null) 'warranty_expiry': _warrantyExpiry!.toIso8601String(),
        if (_lastChargedAt != null) 'last_charged_at': _lastChargedAt!.toIso8601String(),
        if (_lastInspectedAt != null) 'last_inspected_at': _lastInspectedAt!.toIso8601String(),
        if (_lastMaintenanceDate != null) 'last_maintenance_date': _lastMaintenanceDate!.toIso8601String(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };
      data.removeWhere((_, v) => v == null);

      await _repo.createBattery(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Battery registered in central inventory'),
            backgroundColor: _kGreen,
          ),
        );
        widget.onSuccess();
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildLeftColumn()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildRightColumn()),
                      ],
                    );
                  }
                  return Column(
                    children: [_buildLeftColumn(), const SizedBox(height: 24), _buildRightColumn()],
                  );
                },
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdentitySection(),
        const SizedBox(height: 24),
        _buildCatalogSection(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHealthSection(),
        const SizedBox(height: 24),
        _buildCostsSection(),
        const SizedBox(height: 24),
        _buildDatesSection(),
        const SizedBox(height: 24),
        _buildNotesSection(),
      ],
    );
  }

  // ── IDENTITY ──────────────────────────────────────────────────────────────

  Widget _buildIdentitySection() {
    return _section('Identity', Icons.badge_outlined, [
      Row(children: [
        Expanded(
          child: _textField(
            _serialCtrl, 'Serial Number',
            icon: Icons.qr_code,
            monospace: true,
            required: true,
            hint: 'BAT-2025-0001',
          ),
        ),
        const SizedBox(width: 8),
        _iconBtn(Icons.refresh_outlined, 'Regenerate', () {
          setState(() => _serialCtrl.text = _generateSerial());
        }),
      ]),
      const SizedBox(height: 14),
      _textField(_manufacturerCtrl, 'Manufacturer', icon: Icons.factory_outlined, hint: 'e.g. BYD, LG, CATL'),
      const SizedBox(height: 14),
      _dropdown('Battery Type', _batteryType, _kBatteryTypes, (v) => setState(() => _batteryType = v!)),
      const SizedBox(height: 14),
      _textField(_iotDeviceCtrl, 'IoT Device ID', icon: Icons.sensors_outlined, hint: 'Optional hardware ID'),
    ]);
  }

  // ── CATALOG LINKS ─────────────────────────────────────────────────────────

  Widget _buildCatalogSection() {
    return _section('Catalog Links', Icons.library_books_outlined, [
      _textField(
        _skuIdCtrl, 'SKU ID (optional)',
        icon: Icons.tag_outlined,
        hint: 'Battery catalog SKU ID',
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 14),
      _textField(
        _specIdCtrl, 'Spec ID (optional)',
        icon: Icons.description_outlined,
        hint: 'Battery spec catalog ID',
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        keyboardType: TextInputType.number,
      ),
    ]);
  }

  // ── HEALTH ────────────────────────────────────────────────────────────────

  Widget _buildHealthSection() {
    return _section('Health & Initial State', Icons.favorite_outline, [
      _sliderField('Initial Health %', _healthPct, (v) => setState(() {
        _healthPct = v;
        _stateOfHealth = v;
      })),
      const SizedBox(height: 14),
      _sliderField('State of Health (SoH) %', _stateOfHealth, (v) => setState(() => _stateOfHealth = v)),
      const SizedBox(height: 14),
      _sliderField('Current Charge %', _currentCharge, (v) => setState(() => _currentCharge = v),
        color: const Color(0xFF3B82F6)),
      const SizedBox(height: 14),
      _dropdown('Health Status', _healthStatus, _kHealthStatuses, (v) => setState(() => _healthStatus = v!)),
      const SizedBox(height: 14),
      _textField(
        _tempCtrl, 'Temperature (°C)',
        icon: Icons.thermostat_outlined,
        hint: '25.0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      ),
    ]);
  }

  // ── COSTS & CYCLES ────────────────────────────────────────────────────────

  Widget _buildCostsSection() {
    return _section('Costs & Cycle Tracking', Icons.analytics_outlined, [
      _textField(
        _purchaseCostCtrl, 'Purchase Cost (₹)',
        icon: Icons.currency_rupee_outlined,
        hint: '0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _textField(
          _cycleCountCtrl, 'Cycle Count',
          hint: '0',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        )),
        const SizedBox(width: 12),
        Expanded(child: _textField(
          _totalCyclesCtrl, 'Total Design Cycles',
          hint: '0',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        )),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _textField(
          _chargeCyclesCtrl, 'Charge Cycles',
          hint: '0',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        )),
        const SizedBox(width: 12),
        Expanded(child: _textField(
          _lastMaintenanceCyclesCtrl, 'Cycles @ Last Maintenance',
          hint: '0',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        )),
      ]),
    ]);
  }

  // ── DATES ─────────────────────────────────────────────────────────────────

  Widget _buildDatesSection() {
    return _section('Lifecycle Dates', Icons.calendar_month_outlined, [
      _datePicker('Manufacture Date', _manufactureDate, (d) => setState(() => _manufactureDate = d)),
      const SizedBox(height: 14),
      _datePicker('Purchase Date', _purchaseDate, (d) {
        setState(() => _purchaseDate = d);
        _updateWarrantyFromMonths();
      }),
      const SizedBox(height: 14),

      // Warranty period selector
      const Text('Warranty Period', style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: _kWarrantyMonthOptions.map((m) {
        final active = _warrantyMonths == m;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () { setState(() => _warrantyMonths = m); _updateWarrantyFromMonths(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active ? _kBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? _kBlue : _kBorder),
              ),
              child: Text('${m}m', style: TextStyle(
                color: active ? _kBlue : Colors.white38,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              )),
            ),
          ),
        );
      }).toList()),
      if (_warrantyExpiry != null) ...[
        const SizedBox(height: 6),
        Text('Warranty expires: ${DateFormat('dd MMM yyyy').format(_warrantyExpiry!)}',
          style: const TextStyle(color: Colors.white30, fontSize: 11)),
      ],
      const SizedBox(height: 14),
      _datePicker('Last Charged At (optional)', _lastChargedAt, (d) => setState(() => _lastChargedAt = d)),
      const SizedBox(height: 14),
      _datePicker('Last Inspected At (optional)', _lastInspectedAt, (d) => setState(() => _lastInspectedAt = d)),
      const SizedBox(height: 14),
      _datePicker('Last Maintenance Date (optional)', _lastMaintenanceDate, (d) => setState(() => _lastMaintenanceDate = d)),
    ]);
  }

  // ── NOTES ─────────────────────────────────────────────────────────────────

  Widget _buildNotesSection() {
    return _section('Notes', Icons.notes_outlined, [
      TextFormField(
        controller: _notesCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 4,
        decoration: _inputDeco('Internal notes, batch info, observations...', null),
      ),
    ]);
  }

  // ── FOOTER ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(children: [
        OutlinedButton(
          onPressed: () => context.go('/fleet/batteries'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.check, size: 18, color: Colors.white),
            label: Text(_isSaving ? 'Registering...' : 'Register Battery',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── SHARED WIDGET HELPERS ─────────────────────────────────────────────────

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderFaint),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: _kBlue),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.2)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    bool monospace = false,
    bool required = false,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      style: monospace
          ? GoogleFonts.firaCode(color: Colors.white, fontSize: 14)
          : const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
      decoration: _inputDeco(hint ?? label, icon),
    );
  }

  InputDecoration _inputDeco(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.2)) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : options.first,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          border: InputBorder.none,
        ),
        dropdownColor: _kSurface,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30, size: 20),
      ),
    );
  }

  Widget _sliderField(String label, double value, ValueChanged<double> onChanged, {Color? color}) {
    final pct = value.clamp(0.0, 100.0);
    final trackColor = color ?? (pct > 80 ? _kGreen : (pct > 50 ? const Color(0xFFF59E0B) : Colors.redAccent));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: trackColor,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
              thumbColor: trackColor,
              overlayColor: trackColor.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(value: pct, min: 0, max: 100, divisions: 100, onChanged: onChanged),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: trackColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${pct.toInt()}%', style: TextStyle(color: trackColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
    ]);
  }

  Widget _datePicker(String label, DateTime? value, ValueChanged<DateTime> onSelected) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime(2040),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: _kBlue, surface: _kSurface),
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
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 15, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            value != null ? DateFormat('dd MMM yyyy').format(value) : label,
            style: TextStyle(color: value != null ? Colors.white : Colors.white38, fontSize: 14),
          )),
          if (value != null) GestureDetector(
            onTap: () {
              // This won't fire from the outer tap — handled via separate tap target
            },
            child: Icon(Icons.close, size: 15, color: Colors.white.withValues(alpha: 0.2)),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: _kBlue, size: 20),
        style: IconButton.styleFrom(backgroundColor: _kBlue.withValues(alpha: 0.1)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BULK BATTERIES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _BulkBatteriesTab extends StatefulWidget {
  final VoidCallback onSuccess;
  const _BulkBatteriesTab({required this.onSuccess});

  @override
  State<_BulkBatteriesTab> createState() => _BulkBatteriesTabState();
}

class _BulkBatteriesTabState extends State<_BulkBatteriesTab> {
  final _repo = InventoryRepository();
  bool _isSaving = false;

  // Serial number rows
  final List<TextEditingController> _serialCtrls = [];
  final _scrollController = ScrollController();

  // Shared defaults
  String _batteryType = '48V/30Ah';
  String _healthStatus = 'good';
  double _healthPct = 100.0;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _purchaseCostCtrl;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  int _warrantyMonths = 24;
  late final TextEditingController _notesCtrl;

  // Result tracking
  List<Map<String, dynamic>>? _results;

  @override
  void initState() {
    super.initState();
    _manufacturerCtrl = TextEditingController();
    _purchaseCostCtrl = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();
    // Start with 3 rows
    for (var i = 0; i < 3; i++) {
      _addRow();
    }
  }

  @override
  void dispose() {
    for (final c in _serialCtrls) { c.dispose(); }
    _manufacturerCtrl.dispose();
    _purchaseCostCtrl.dispose();
    _notesCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addRow() {
    final year = DateTime.now().year;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    setState(() => _serialCtrls.add(TextEditingController(text: 'BAT-$year-$rand')));
  }

  void _removeRow(int index) {
    if (_serialCtrls.length <= 1) return;
    final ctrl = _serialCtrls.removeAt(index);
    ctrl.dispose();
    setState(() {});
  }

  void _updateWarrantyFromMonths() {
    if (_purchaseDate != null) {
      setState(() {
        _warrantyExpiry = DateTime(
          _purchaseDate!.year,
          _purchaseDate!.month + _warrantyMonths,
          _purchaseDate!.day,
        );
      });
    }
  }

  Future<void> _save() async {
    // Validate: all serials non-empty, no duplicates within batch
    final serials = _serialCtrls.map((c) => c.text.trim().toUpperCase()).toList();
    final emptyIdx = serials.indexWhere((s) => s.isEmpty);
    if (emptyIdx != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Row ${emptyIdx + 1}: serial number is required'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final uniqueSerials = serials.toSet();
    if (uniqueSerials.length != serials.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duplicate serial numbers in batch'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() { _isSaving = true; _results = null; });

    try {
      final sharedDefaults = <String, dynamic>{
        'battery_type': _batteryType,
        'health_status': _healthStatus,
        'status': 'available',
        'location_type': 'warehouse',
        'health_percentage': _healthPct,
        'current_charge': 100.0,
        'state_of_health': _healthPct,
        'purchase_cost': double.tryParse(_purchaseCostCtrl.text) ?? 0.0,
        if (_manufacturerCtrl.text.trim().isNotEmpty) 'manufacturer': _manufacturerCtrl.text.trim(),
        if (_purchaseDate != null) 'purchase_date': _purchaseDate!.toIso8601String(),
        if (_warrantyExpiry != null) 'warranty_expiry': _warrantyExpiry!.toIso8601String(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };

      final items = serials.map((s) => <String, dynamic>{...sharedDefaults, 'serial_number': s}).toList();

      final created = await _repo.createBatteryBulk(items);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _results = created.map((b) => {'serial': b.serialNumber, 'id': b.id, 'ok': true}).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${created.length} batteries registered in central inventory'),
            backgroundColor: _kGreen,
          ),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildSerialsList()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildSharedDefaults()),
                    ],
                  );
                }
                return Column(children: [_buildSerialsList(), const SizedBox(height: 24), _buildSharedDefaults()]);
              },
            ),
          ),
        ),
        _buildBulkFooter(),
      ],
    );
  }

  Widget _buildSerialsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Expanded(
            child: _sectionHeader('Serial Numbers', Icons.list_outlined,
              '${_serialCtrls.length} batteries to register'),
          ),
          _addRowButton(),
        ]),
        const SizedBox(height: 16),

        // Serial rows
        ..._serialCtrls.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _serialRow(entry.key, entry.value),
        )),

        const SizedBox(height: 8),
        _addMoreButton(),

        // Results
        if (_results != null) ...[
          const SizedBox(height: 20),
          _buildResults(),
        ],
      ],
    );
  }

  Widget _serialRow(int index, TextEditingController ctrl) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _kBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('${index + 1}', style: const TextStyle(color: _kBlue, fontSize: 12, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: ctrl,
          style: GoogleFonts.firaCode(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'BAT-2025-XXXX',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: _serialCtrls.length > 1 ? () => _removeRow(index) : null,
        icon: Icon(Icons.remove_circle_outline, size: 18,
          color: _serialCtrls.length > 1 ? Colors.redAccent.withValues(alpha: 0.7) : Colors.white12),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    ]);
  }

  Widget _addMoreButton() {
    return GestureDetector(
      onTap: _addRow,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), style: BorderStyle.solid),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, size: 16, color: Colors.white38),
          SizedBox(width: 6),
          Text('Add Another', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _addRowButton() {
    return TextButton.icon(
      onPressed: _addRow,
      icon: const Icon(Icons.add, size: 16, color: _kBlue),
      label: const Text('Add Row', style: TextStyle(color: _kBlue, fontSize: 13)),
    );
  }

  Widget _buildResults() {
    final results = _results!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_outline, size: 16, color: _kGreen),
          const SizedBox(width: 8),
          Text('${results.length} batteries registered', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        ...results.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.check, size: 13, color: _kGreen),
            const SizedBox(width: 8),
            Text(r['serial'] as String, style: GoogleFonts.firaCode(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Text('ID: ${r['id']}', style: const TextStyle(color: Colors.white30, fontSize: 11)),
          ]),
        )),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: widget.onSuccess,
          child: const Text('View all batteries →', style: TextStyle(color: _kBlue, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildSharedDefaults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderFaint),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Shared Defaults', Icons.tune_outlined, 'Applied to all batteries in this batch'),
        const SizedBox(height: 16),

        _dropdown('Battery Type', _batteryType, _kBatteryTypes, (v) => setState(() => _batteryType = v!)),
        const SizedBox(height: 14),
        _dropdown('Health Status', _healthStatus, _kHealthStatuses, (v) => setState(() => _healthStatus = v!)),
        const SizedBox(height: 14),
        _textField(_manufacturerCtrl, 'Manufacturer', hint: 'Optional'),
        const SizedBox(height: 14),
        _textField(
          _purchaseCostCtrl, 'Purchase Cost (₹)',
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        ),
        const SizedBox(height: 14),

        // Health slider
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Initial Health %', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _kGreen,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
                  thumbColor: _kGreen,
                  overlayColor: _kGreen.withValues(alpha: 0.1),
                  trackHeight: 5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(value: _healthPct, min: 0, max: 100, divisions: 100,
                  onChanged: (v) => setState(() => _healthPct = v)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
              child: Text('${_healthPct.toInt()}%', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
        ]),
        const SizedBox(height: 14),

        _datePicker('Purchase Date', _purchaseDate, (d) {
          setState(() => _purchaseDate = d);
          _updateWarrantyFromMonths();
        }),
        const SizedBox(height: 14),

        const Text('Warranty Period', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _kWarrantyMonthOptions.map((m) {
          final active = _warrantyMonths == m;
          return GestureDetector(
            onTap: () { setState(() => _warrantyMonths = m); _updateWarrantyFromMonths(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _kBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: active ? _kBlue : _kBorder),
              ),
              child: Text('${m}m', style: TextStyle(
                color: active ? _kBlue : Colors.white38,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal, fontSize: 12,
              )),
            ),
          );
        }).toList()),
        if (_warrantyExpiry != null) ...[
          const SizedBox(height: 6),
          Text('Expires: ${DateFormat('dd MMM yyyy').format(_warrantyExpiry!)}',
            style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ],
        const SizedBox(height: 14),
        _textField(_notesCtrl, 'Batch Notes', hint: 'Optional notes for this batch'),
      ]),
    );
  }

  Widget _buildBulkFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(children: [
        OutlinedButton(
          onPressed: () => context.go('/fleet/batteries'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        const SizedBox(width: 12),
        Text('${_serialCtrls.length} batteries', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.upload_outlined, size: 18, color: Colors.white),
            label: Text(_isSaving ? 'Registering...' : 'Register All Batteries',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Bulk widget helpers ────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon, String subtitle) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: _kBlue),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 11)),
      ]),
    ]);
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : options.first,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 13), border: InputBorder.none),
        dropdownColor: _kSurface,
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
          firstDate: DateTime(2015),
          lastDate: DateTime(2040),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: _kBlue, surface: _kSurface),
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
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 15, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            value != null ? DateFormat('dd MMM yyyy').format(value) : label,
            style: TextStyle(color: value != null ? Colors.white : Colors.white38, fontSize: 14),
          )),
        ]),
      ),
    );
  }
}
