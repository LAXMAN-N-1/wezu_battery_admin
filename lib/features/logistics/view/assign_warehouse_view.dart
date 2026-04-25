import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/logistics_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kSurface2 = Color(0xFF243044);
const _kBlue = Color(0xFF3B82F6);
const _kGreen = Color(0xFF22C55E);
const _kAmber = Color(0xFFF59E0B);
const _kBorder = Color(0x10FFFFFF);
const _kText = Colors.white;
const _kTextMuted = Color(0xFF94A3B8);
const _kBatteryTypes = ['48V/30Ah', '60V/40Ah', '72V/50Ah', '96V/60Ah'];

// ─────────────────────────────────────────────────────────────────────────────
// Root view
// ─────────────────────────────────────────────────────────────────────────────

class AssignWarehouseView extends StatefulWidget {
  const AssignWarehouseView({super.key});

  @override
  State<AssignWarehouseView> createState() => _AssignWarehouseViewState();
}

class _AssignWarehouseViewState extends State<AssignWarehouseView> {
  final LogisticsRepository _repo = LogisticsRepository();

  // Battery list state
  List<Map<String, dynamic>> _batteries = [];
  bool _batteriesLoading = false;
  String? _batteriesError;
  int _totalBatteries = 0;
  int _offset = 0;
  static const _limit = 50;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedBatteryType;
  final Set<int> _selectedIds = {};

  // Warehouse state
  List<Map<String, dynamic>> _warehouses = [];
  bool _warehousesLoading = false;
  String? _warehousesError;
  int? _selectedWarehouseId;

  // Assignment state
  final TextEditingController _notesCtrl = TextEditingController();
  bool _assigning = false;
  Map<String, dynamic>? _assignResult;

  @override
  void initState() {
    super.initState();
    _loadBatteries();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadBatteries({bool reset = false}) async {
    if (reset) {
      _offset = 0;
      _selectedIds.clear();
    }
    setState(() {
      _batteriesLoading = true;
      _batteriesError = null;
    });
    try {
      final result = await _repo.getCentralInventoryBatteries(
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        batteryType: _selectedBatteryType,
        offset: _offset,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        if (reset || _offset == 0) {
          _batteries = List<Map<String, dynamic>>.from(result['items'] as List);
        } else {
          _batteries.addAll(List<Map<String, dynamic>>.from(result['items'] as List));
        }
        _totalBatteries = (result['total_count'] as num?)?.toInt() ?? _batteries.length;
        _batteriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _batteriesError = e.toString();
        _batteriesLoading = false;
      });
    }
  }

  Future<void> _loadWarehouses() async {
    setState(() {
      _warehousesLoading = true;
      _warehousesError = null;
    });
    try {
      final list = await _repo.getWarehouses();
      if (!mounted) return;
      setState(() {
        _warehouses = list;
        _warehousesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _warehousesError = e.toString();
        _warehousesLoading = false;
      });
    }
  }

  Future<void> _assign() async {
    if (_selectedIds.isEmpty) {
      _showSnack('Select at least one battery', isError: true);
      return;
    }
    if (_selectedWarehouseId == null) {
      _showSnack('Select a target warehouse', isError: true);
      return;
    }
    setState(() {
      _assigning = true;
      _assignResult = null;
    });
    try {
      final result = await _repo.assignBatteriesToWarehouse(
        batteryIds: _selectedIds.toList(),
        warehouseId: _selectedWarehouseId!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _assignResult = result;
        _assigning = false;
        _selectedIds.clear();
      });
      await _loadBatteries(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigning = false);
      _showSnack('Assignment failed: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: isError ? const Color(0xFFEF4444) : _kGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlowBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildBatteryPanel()),
                  const SizedBox(width: 20),
                  SizedBox(width: 340, child: _buildAssignPanel()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Flow Banner ──────────────────────────────────────────────────────────

  Widget _buildFlowBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warehouse_outlined, color: _kBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Batteries from Central Inventory to Warehouse',
                  style: GoogleFonts.inter(
                    color: _kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select batteries from central inventory (unassigned), choose target warehouse, then confirm assignment. Assigned batteries will be ready to fulfill dealer station orders.',
                  style: GoogleFonts.inter(color: _kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _buildFlowStep('Central\nInventory', Icons.inventory_2_outlined, _kBlue),
          const Icon(Icons.arrow_forward, color: _kTextMuted, size: 16),
          _buildFlowStep('Warehouse', Icons.warehouse_outlined, _kAmber),
          const Icon(Icons.arrow_forward, color: _kTextMuted, size: 16),
          _buildFlowStep('Dealer\nStation', Icons.ev_station_outlined, _kGreen),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildFlowStep(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── Battery Panel ────────────────────────────────────────────────────────

  Widget _buildBatteryPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBatteryPanelHeader(),
          _buildBatteryFilters(),
          _buildSelectedBanner(),
          Expanded(child: _buildBatteryList()),
          if (_batteries.length < _totalBatteries) _buildLoadMoreButton(),
        ],
      ),
    );
  }

  Widget _buildBatteryPanelHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: _kBlue, size: 20),
          const SizedBox(width: 10),
          Text(
            'Central Inventory',
            style: GoogleFonts.inter(color: _kText, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalBatteries unassigned',
              style: GoogleFonts.inter(color: _kBlue, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          if (_batteriesLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: _kTextMuted, size: 18),
            tooltip: 'Refresh',
            onPressed: () => _loadBatteries(reset: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: _kText, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search serial number...',
                hintStyle: GoogleFonts.inter(color: _kTextMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _kTextMuted, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: _kTextMuted, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadBatteries(reset: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBlue),
                ),
              ),
              onSubmitted: (_) => _loadBatteries(reset: true),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBatteryType,
              dropdownColor: _kSurface2,
              style: GoogleFonts.inter(color: _kText, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'All types',
                hintStyle: GoogleFonts.inter(color: _kTextMuted, fontSize: 13),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBlue),
                ),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All types', style: GoogleFonts.inter(color: _kTextMuted, fontSize: 13)),
                ),
                ..._kBatteryTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: GoogleFonts.inter(color: _kText, fontSize: 13)),
                    )),
              ],
              onChanged: (v) {
                setState(() => _selectedBatteryType = v);
                _loadBatteries(reset: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          if (_selectedIds.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _selectedIds.clear()),
              icon: const Icon(Icons.deselect, size: 16, color: _kTextMuted),
              label: Text(
                'Clear (${_selectedIds.length})',
                style: GoogleFonts.inter(color: _kTextMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedBanner() {
    if (_selectedIds.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _kBlue, size: 16),
          const SizedBox(width: 8),
          Text(
            '${_selectedIds.length} batter${_selectedIds.length == 1 ? 'y' : 'ies'} selected',
            style: GoogleFonts.inter(color: _kBlue, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                for (final b in _batteries) {
                  final id = (b['id'] as num?)?.toInt();
                  if (id != null) _selectedIds.add(id);
                }
              });
            },
            child: Text(
              'Select all ${_batteries.length} visible',
              style: GoogleFonts.inter(
                color: _kBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryList() {
    if (_batteriesLoading && _batteries.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }
    if (_batteriesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 12),
            Text(_batteriesError!, style: GoogleFonts.inter(color: _kTextMuted, fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _loadBatteries(reset: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: _kBlue, side: const BorderSide(color: _kBlue)),
            ),
          ],
        ),
      );
    }
    if (_batteries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: _kTextMuted.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text('No batteries in central inventory', style: GoogleFonts.inter(color: _kTextMuted, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Add batteries via Fleet & Inventory → Add Batteries', style: GoogleFonts.inter(color: _kTextMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _batteries.length,
      itemBuilder: (context, index) => _buildBatteryRow(_batteries[index], index),
    );
  }

  Widget _buildBatteryRow(Map<String, dynamic> battery, int index) {
    final id = (battery['id'] as num?)?.toInt() ?? 0;
    final serial = battery['serial_number'] as String? ?? '—';
    final type = battery['battery_type'] as String? ?? '—';
    final health = (battery['health_percentage'] as num?)?.toDouble() ?? 100.0;
    final status = battery['status'] as String? ?? 'available';
    final selected = _selectedIds.contains(id);

    Color healthColor = _kGreen;
    if (health < 60) {
      healthColor = const Color(0xFFEF4444);
    } else if (health < 80) {
      healthColor = _kAmber;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(id);
          } else {
            _selectedIds.add(id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kBlue.withValues(alpha: 0.1) : _kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _kBlue.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) {
                setState(() {
                  if (selected) {
                    _selectedIds.remove(id);
                  } else {
                    _selectedIds.add(id);
                  }
                });
              },
              activeColor: _kBlue,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.battery_full, color: _kBlue, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serial,
                    style: GoogleFonts.inter(color: _kText, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    type,
                    style: GoogleFonts.inter(color: _kTextMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: healthColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${health.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(color: healthColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 15)).fadeIn(duration: 200.ms),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _batteriesLoading
              ? null
              : () {
                  _offset += _limit;
                  _loadBatteries();
                },
          icon: _batteriesLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
                )
              : const Icon(Icons.expand_more, size: 16),
          label: Text('Load more (${_totalBatteries - _batteries.length} remaining)'),
          style: OutlinedButton.styleFrom(foregroundColor: _kBlue, side: const BorderSide(color: _kBlue)),
        ),
      ),
    );
  }

  // ─── Assign Panel ─────────────────────────────────────────────────────────

  Widget _buildAssignPanel() {
    return Column(
      children: [
        _buildWarehouseCard(),
        const SizedBox(height: 16),
        if (_assignResult != null) _buildResultCard(),
      ],
    );
  }

  Widget _buildWarehouseCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.warehouse_outlined, color: _kAmber, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Assign to Warehouse',
                  style: GoogleFonts.inter(color: _kText, fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Target Warehouse'),
                const SizedBox(height: 8),
                _buildWarehouseDropdown(),
                const SizedBox(height: 20),
                _buildSectionLabel('Notes (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  style: GoogleFonts.inter(color: _kText, fontSize: 13),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Reason for assignment, batch info...',
                    hintStyle: GoogleFonts.inter(color: _kTextMuted, fontSize: 13),
                    filled: true,
                    fillColor: _kBg,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildAssignSummary(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildAssignButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(color: _kTextMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  Widget _buildWarehouseDropdown() {
    if (_warehousesLoading) {
      return Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
        ),
      );
    }
    if (_warehousesError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load warehouses',
                style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 12),
              ),
            ),
            GestureDetector(
              onTap: _loadWarehouses,
              child: const Icon(Icons.refresh, color: Color(0xFFEF4444), size: 16),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: _selectedWarehouseId,
      dropdownColor: _kSurface2,
      isExpanded: true,
      style: GoogleFonts.inter(color: _kText, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Select warehouse...',
        hintStyle: GoogleFonts.inter(color: _kTextMuted, fontSize: 13),
        filled: true,
        fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue),
        ),
      ),
      items: _warehouses.map((w) {
        final id = (w['id'] as num?)?.toInt() ?? 0;
        final name = w['name'] as String? ?? 'Warehouse $id';
        final city = w['city'] as String?;
        return DropdownMenuItem<int>(
          value: id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: GoogleFonts.inter(color: _kText, fontSize: 13)),
              if (city != null)
                Text(city, style: GoogleFonts.inter(color: _kTextMuted, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedWarehouseId = v),
    );
  }

  Widget _buildAssignSummary() {
    final warehouseName = _selectedWarehouseId != null
        ? (_warehouses.firstWhere(
              (w) => (w['id'] as num?)?.toInt() == _selectedWarehouseId,
              orElse: () => {},
            )['name'] as String?) ??
            'Unknown'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Batteries selected',
            _selectedIds.isEmpty ? 'None' : '${_selectedIds.length}',
            _selectedIds.isEmpty ? _kTextMuted : _kBlue,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Target warehouse',
            warehouseName ?? 'Not selected',
            warehouseName != null ? _kAmber : _kTextMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: _kTextMuted, fontSize: 12)),
        Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAssignButton() {
    final canAssign = _selectedIds.isNotEmpty && _selectedWarehouseId != null;
    if (_assigning) {
      return Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kBlue, Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: canAssign ? _assign : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          gradient: canAssign
              ? const LinearGradient(colors: [_kBlue, Color(0xFF2563EB)])
              : null,
          color: canAssign ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: canAssign ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.move_to_inbox_outlined,
              color: canAssign ? Colors.white : _kTextMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Assign to Warehouse',
              style: GoogleFonts.inter(
                color: canAssign ? Colors.white : _kTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Card ──────────────────────────────────────────────────────────

  Widget _buildResultCard() {
    final result = _assignResult!;
    final assigned = (result['assigned_count'] as num?)?.toInt() ?? 0;
    final skipped = (result['skipped_count'] as num?)?.toInt() ?? 0;
    final warehouseName = result['warehouse_name'] as String? ?? 'Warehouse';
    final skippedSerials = (result['skipped_serials'] as List?)?.cast<String>() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: _kGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Assignment Complete',
                  style: GoogleFonts.inter(color: _kGreen, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultRow(Icons.check_circle_outline, '$assigned batteries', 'assigned to $warehouseName', _kGreen),
                if (skipped > 0) ...[
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.skip_next_outlined, '$skipped batteries', 'skipped (not in central inventory)', _kAmber),
                ],
                if (skippedSerials.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Skipped: ${skippedSerials.join(', ')}',
                    style: GoogleFonts.inter(color: _kTextMuted, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _assignResult = null),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.inter(
                      color: _kTextMuted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildResultRow(IconData icon, String primary, String secondary, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$primary ',
                style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: secondary,
                style: GoogleFonts.inter(color: _kTextMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
