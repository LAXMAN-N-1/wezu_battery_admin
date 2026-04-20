import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/battery.dart';
import '../data/repositories/inventory_repository.dart';
import '../widgets/battery_form_drawer.dart';
import '../widgets/battery_detail_drawer.dart';
import '../widgets/battery_import_modal.dart';
import '../widgets/battery_qr_modal.dart';
import '../../../core/widgets/wezu_skeleton.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class BatteriesView extends StatefulWidget {
  const BatteriesView({super.key});

  @override
  State<BatteriesView> createState() => _BatteriesViewState();
}

class _BatteriesViewState extends SafeState<BatteriesView>
    with TickerProviderStateMixin {
  final InventoryRepository _repository = InventoryRepository();
  List<Battery> _batteries = [];
  Map<String, dynamic> _summary = {
    "total_batteries": 0,
    "available_count": 0,
    "rented_count": 0,
    "maintenance_count": 0,
    "retired_count": 0,
    "utilization_percentage": 0.0,
  };
  bool _isLoading = true;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _locationFilter = 'All';
  String _batteryTypeFilter = 'All';
  String _healthFilter = 'All';
  String _quickFilter = 'All';

  // Pagination
  int _currentPage = 0;
  int _rowsPerPage = 20;
  int _totalCount = 0;

  // Selection
  final Set<String> _selectedIds = {};
  bool get _allSelected =>
      _batteries.isNotEmpty && _selectedIds.length == _batteries.length;

  // Animation controllers
  late AnimationController _bulkBarController;

  @override
  void initState() {
    super.initState();
    _bulkBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _bulkBarController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      double? minHealth;
      double? maxHealth;
      if (_healthFilter == 'Good >80%') {
        minHealth = 80;
      } else if (_healthFilter == 'Fair 50-80%') {
        minHealth = 50;
        maxHealth = 80;
      } else if (_healthFilter == 'Poor <50%') {
        maxHealth = 50;
      }

      // Apply quick filter overrides
      String? effectiveStatus = _statusFilter;
      if (_quickFilter == 'Needs Attention') {
        maxHealth = 60;
        effectiveStatus = 'All';
      }

      final results = await Future.wait([
        _repository.getBatteries(
          status: effectiveStatus,
          locationType: _locationFilter,
          batteryType: _batteryTypeFilter,
          minHealth: minHealth,
          maxHealth: maxHealth,
          search: _searchQuery,
          offset: _currentPage * _rowsPerPage,
          limit: _rowsPerPage,
        ),
        _repository.getBatterySummary(),
      ]);

      if (mounted) {
        final listResult = results[0];
        setState(() {
          _batteries = listResult['items'] as List<Battery>;
          _totalCount = (listResult['total_count'] is num)
              ? (listResult['total_count'] as num).toInt()
              : int.tryParse(listResult['total_count']?.toString() ?? '') ?? 0;
          _summary = results[1];
          _isLoading = false;
          _selectedIds.clear();
          _bulkBarController.reverse();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _loadDataSilently() async {
    try {
      double? minHealth;
      double? maxHealth;
      if (_healthFilter == 'Good >80%') {
        minHealth = 80;
      } else if (_healthFilter == 'Fair 50-80%') { minHealth = 50; maxHealth = 80; }
      else if (_healthFilter == 'Poor <50%') maxHealth = 50;

      String? effectiveStatus = _statusFilter;
      if (_quickFilter == 'Needs Attention') {
        maxHealth = 60;
        effectiveStatus = 'All';
      }

      final results = await Future.wait([
        _repository.getBatteries(
          status: effectiveStatus,
          locationType: _locationFilter,
          batteryType: _batteryTypeFilter,
          minHealth: minHealth,
          maxHealth: maxHealth,
          search: _searchQuery,
          offset: _currentPage * _rowsPerPage,
          limit: _rowsPerPage,
        ),
        _repository.getBatterySummary(),
      ]);

      if (mounted) {
        final listResult = results[0];
        setState(() {
          _batteries = listResult['items'] as List<Battery>;
          _totalCount = (listResult['total_count'] is num) ? (listResult['total_count'] as num).toInt() : int.tryParse(listResult['total_count']?.toString() ?? '') ?? 0;
          _summary = results[1];
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _currentPage = 0;
      });
      _loadData();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isNotEmpty) {
        _bulkBarController.forward();
      } else {
        _bulkBarController.reverse();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
        _bulkBarController.reverse();
      } else {
        _selectedIds.addAll(_batteries.map((b) => b.id));
        _bulkBarController.forward();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _bulkBarController.reverse();
    });
  }

  void _applyQuickFilter(String filter) {
    setState(() {
      _quickFilter = filter;
      _statusFilter = 'All';
      _locationFilter = 'All';
      _healthFilter = 'All';
      _batteryTypeFilter = 'All';
      _currentPage = 0;
    });
    _loadData();
  }

  void _applyStatCardFilter(String status) {
    setState(() {
      _statusFilter = status;
      _quickFilter = 'All';
      _currentPage = 0;
    });
    _loadData();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_statusFilter != 'All') count++;
    if (_locationFilter != 'All') count++;
    if (_batteryTypeFilter != 'All') count++;
    if (_healthFilter != 'All') count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilter = 'All';
      _locationFilter = 'All';
      _batteryTypeFilter = 'All';
      _healthFilter = 'All';
      _quickFilter = 'All';
      _searchQuery = '';
      _searchController.clear();
      _currentPage = 0;
    });
    _loadData();
  }

  void _openAddDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Battery',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 450,
              child: BatteryFormDrawer(onSaved: _loadData),
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(a1),
        child: child,
      ),
    );
  }

  void _openEditDrawer(Battery battery) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Battery',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 450,
              child: BatteryFormDrawer(battery: battery, onSaved: _loadData),
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(a1),
        child: child,
      ),
    );
  }

  void _openDetailDrawer(Battery battery) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Battery Details',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 450,
              child: BatteryDetailDrawer(battery: battery),
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(a1),
        child: child,
      ),
    );
  }

  void _viewQR(Battery battery) {
    showDialog(
      context: context,
      builder: (context) => BatteryQRModal(
        serialNumber: battery.serialNumber,
        qrData: 'WEZU_BAT_${battery.serialNumber}',
      ),
    );
  }

  Future<void> _exportInventory() async {
    try {
      await _repository.exportBatteries(
        status: _statusFilter,
        locationType: _locationFilter,
        batteryType: _batteryTypeFilter,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export download started'),
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _bulkChangeStatus(String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change ${_selectedIds.length} batteries to $status?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'This action will be logged in the audit trail.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final selectedCopy = _selectedIds.toList();
      setState(() {
        for (var i = 0; i < _batteries.length; i++) {
          if (_selectedIds.contains(_batteries[i].id)) {
            _batteries[i] = _batteries[i].copyWith(status: status);
          }
        }
        _selectedIds.clear();
        _bulkBarController.reverse();
      });

      try {
        _repository.bulkUpdateBatteries(selectedCopy, status).then((_) {
          _loadDataSilently();
        }).catchError((_) {
          _loadDataSilently(); // Re-sync on failure safely
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedCopy.length} batteries updated to $status',
              ),
              backgroundColor: Colors.greenAccent.shade700,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _confirmDelete(Battery battery) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            const Text('Retire Battery', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to retire ${battery.serialNumber}?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'A reason is required for audit tracking.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason for retirement',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              try {
                final copyId = battery.id;
                setState(() => _batteries.removeWhere((b) => b.id == copyId));

                _repository.deleteBattery(
                  copyId,
                  reason: reasonController.text,
                ).then((_) {
                  _loadDataSilently();
                }).catchError((_) {
                  _loadDataSilently();
                });

                if (!context.mounted || !mounted) {
                  return;
                }
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted || !mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirm Retirement',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildQuickFilters(),
                  const SizedBox(height: 20),
                  _buildFilterBar(),
                  const SizedBox(height: 20),
                  _buildTableCard(),
                  const SizedBox(height: 16),
                  _buildPagination(),
                ],
              ),
            ),
          ),
          // Bulk Action Bar
          _buildBulkActionBar(),
        ],
      );
  }

  // =========================================================================
  // HEADER
  // =========================================================================
  Widget _buildHeader() {
    return PageHeader(
      title: 'Battery Management',
      subtitle: 'Monitor fleet health, lifecycle events, and logistics status',
      actionButton: Row(
        children: [
          _outlinedBtn(Icons.download_rounded, 'Export', _exportInventory),
          const SizedBox(width: 10),
          _outlinedBtn(
            Icons.upload_file_rounded,
            'Bulk Import',
            () => showDialog(
              context: context,
              builder: (_) => const BatteryImportModal(),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _openAddDrawer,
              icon: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Add Battery',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _outlinedBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =========================================================================
  // PREMIUM STAT CARDS
  // =========================================================================
  Widget _buildStatsRow() {
    int safeInt(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    double safeDbl(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

    final total = safeInt(_summary['total_batteries']);
    final available = safeInt(_summary['available_count']);
    final rented = safeInt(_summary['rented_count']);
    final maintenance = safeInt(_summary['maintenance_count']);
    final utilization = safeDbl(_summary['utilization_percentage']);

    final pctAvail = total > 0
        ? '${(available / total * 100).toStringAsFixed(0)}% of fleet'
        : '—';
    final pctRent = total > 0
        ? '${(rented / total * 100).toStringAsFixed(0)}% of fleet'
        : '—';
    final pctMaint = total > 0
        ? '${(maintenance / total * 100).toStringAsFixed(0)}% of fleet'
        : '—';
    final maintWarn = total > 0 && (maintenance / total * 100) > 20;

    return Row(
      children: [
        Expanded(
          child: _premiumStatCard(
            'Fleet Total',
            '$total',
            Icons.analytics_outlined,
            const Color(0xFF3B82F6),
            null,
            'All',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _premiumStatCard(
            'Ready/Available',
            '$available',
            Icons.check_circle_outline_rounded,
            const Color(0xFF22C55E),
            pctAvail,
            'Available',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _premiumStatCard(
            'On Rent',
            '$rented',
            Icons.electric_bike_rounded,
            const Color(0xFF8B5CF6),
            pctRent,
            'Rented',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _premiumStatCard(
            'Service Mode',
            '$maintenance',
            Icons.build_circle_outlined,
            const Color(0xFFF59E0B),
            pctMaint,
            'Maintenance',
            warning: maintWarn,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _premiumStatCard(
            'Utilization',
            '$utilization%',
            Icons.trending_up_rounded,
            const Color(0xFF14B8A6),
            null,
            null,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _premiumStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
    String? filterStatus, {
    bool warning = false,
  }) {
    final isActive = filterStatus != null && _statusFilter == filterStatus;
    return GestureDetector(
      onTap: filterStatus != null
          ? () => _applyStatCardFilter(filterStatus)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.08)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (warning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚠ HIGH',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  // Mini sparkline placeholder (7 dots)
                  Row(
                    children: List.generate(
                      7,
                      (i) => Container(
                        width: 4,
                        height: [8.0, 12.0, 10.0, 14.0, 9.0, 13.0, 11.0][i],
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.3 + i * 0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<int>(
              tween: IntTween(
                begin: 0,
                end:
                    int.tryParse(
                      value.replaceAll('%', '').replaceAll('.', ''),
                    ) ??
                    0,
              ),
              duration: const Duration(milliseconds: 900),
              builder: (context, val, _) {
                final display = value.contains('%')
                    ? '${(val / (value.contains('.') ? 100 : 1)).toStringAsFixed(value.contains('.') ? 2 : 0)}%'
                    : '$val';
                return Text(
                  display,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // QUICK FILTER PILLS
  // =========================================================================
  Widget _buildQuickFilters() {
    final filters = [
      'All',
      'Needs Attention',
      'Expiring Warranty',
      'Idle >7 Days',
      'Recently Added',
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isActive = _quickFilter == f;
          return GestureDetector(
            onTap: () => _applyQuickFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isActive ? const Color(0xFF3B82F6) : Colors.white60,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  // =========================================================================
  // 2-ROW FILTER BAR
  // =========================================================================
  Widget _buildFilterBar() {
    return Column(
      children: [
        // Row 1: Search
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search serial number, manufacturer, model, notes...',
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 0;
                      });
                      _loadData();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Row 2: Filter dropdowns + actions
        Row(
          children: [
            _filterDropdown(
              'Status',
              _statusFilter,
              ['All', 'Available', 'Rented', 'Maintenance', 'Retired'],
              (v) {
                setState(() {
                  _statusFilter = v!;
                  _quickFilter = 'All';
                  _currentPage = 0;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 10),
            _filterDropdown(
              'Location',
              _locationFilter,
              ['All', 'Station', 'Warehouse', 'Service_center', 'Recycling'],
              (v) {
                setState(() {
                  _locationFilter = v!;
                  _currentPage = 0;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 10),
            _filterDropdown(
              'Type',
              _batteryTypeFilter,
              ['All', '48V/30Ah', '60V/40Ah', '72V/50Ah'],
              (v) {
                setState(() {
                  _batteryTypeFilter = v!;
                  _currentPage = 0;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 10),
            _filterDropdown(
              'Health',
              _healthFilter,
              ['All', 'Good >80%', 'Fair 50-80%', 'Poor <50%'],
              (v) {
                setState(() {
                  _healthFilter = v!;
                  _currentPage = 0;
                });
                _loadData();
              },
            ),
            const Spacer(),
            if (_activeFilterCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_activeFilterCount active',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _clearAllFilters,
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _filterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != 'All'
            ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != 'All'
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF0F172A),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white38,
            size: 18,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TABLE WITH CHECKBOXES + NEW COLUMNS
  // =========================================================================
  Widget _buildTableCard() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: WezuSkeletonTable(rows: 10, columns: 8),
            )
          : _batteries.isEmpty
          ? _emptyState()
          : AdvancedTable(
              columns: const ['✓', 'Battery Serial', 'Status', 'Location', 'Type', 'Health', 'Cycles', 'Last Updated', 'Warranty', 'Actions'],
              rows: _batteries.map((b) {
                final selected = _selectedIds.contains(b.id);
                return [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleSelection(b.id),
                    activeColor: const Color(0xFF3B82F6),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  _buildSerialCell(b),
                  _buildStatusCell(b),
                  _buildLocationCell(b),
                  _buildTypeCell(b),
                  _buildHealthCell(b.healthPercentage),
                  Text('${b.cycleCount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  _buildLastUpdatedCell(b),
                  _buildWarrantyCell(b),
                  _buildActionsCell(b),
                ];
              }).toList(),
              onRowTap: (i) => _openDetailDrawer(_batteries[i]),
            ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _emptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.battery_alert_rounded,
              size: 64,
              color: Colors.white10,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Batteries Matching Criteria',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TABLE CELLS
  // =========================================================================
  Widget _buildSerialCell(Battery b) {
    return InkWell(
      onTap: () => _openDetailDrawer(b),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _viewQR(b),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 13,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b.serialNumber,
                  style: GoogleFonts.firaCode(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (b.manufacturer != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  b.manufacturer!,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(Battery b) {
    final statusColors = {
      'available': const Color(0xFF22C55E),
      'rented': const Color(0xFF3B82F6),
      'maintenance': const Color(0xFFF59E0B),
      'retired': const Color(0xFFEF4444),
      'charging': const Color(0xFF8B5CF6),
    };
    final color = statusColors[b.status.toLowerCase()] ?? Colors.grey;
    final isRented = b.status.toLowerCase() == 'rented';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: isRented
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            b.status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCell(Battery b) {
    final icons = {
      'station': Icons.ev_station_rounded,
      'warehouse': Icons.warehouse_rounded,
      'service_center': Icons.build_rounded,
      'recycling': Icons.recycling_rounded,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons[b.locationType.toLowerCase()] ?? Icons.location_on,
              size: 14,
              color: Colors.white38,
            ),
            const SizedBox(width: 4),
            Text(
              b.locationType.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        if (b.locationName != null)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 1),
            child: Text(
              b.locationName!,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeCell(Battery b) {
    final type = b.batteryType ?? '48V/30Ah';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(type, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(
          'Li-ion',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCell(double health) {
    Color color = health > 80
        ? const Color(0xFF22C55E)
        : (health > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    return Tooltip(
      message: 'Health: ${health.toStringAsFixed(1)}%',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: health / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${health.toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedCell(Battery b) {
    final diff = DateTime.now().difference(b.updatedAt);
    String relative;
    if (diff.inMinutes < 60) {
      relative = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      relative = '${diff.inHours}h ago';
    } else if (diff.inDays < 30) {
      relative = '${diff.inDays}d ago';
    } else {
      relative = DateFormat('MMM d').format(b.updatedAt);
    }

    return Tooltip(
      message: DateFormat('yyyy-MM-dd HH:mm:ss').format(b.updatedAt),
      child: Text(
        relative,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildWarrantyCell(Battery b) {
    if (b.warrantyExpiry == null) {
      return Text(
        '—',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 13,
        ),
      );
    }
    final isValid = b.warrantyExpiry!.isAfter(DateTime.now());
    final daysLeft = b.warrantyExpiry!.difference(DateTime.now()).inDays;
    final isExpiringSoon = isValid && daysLeft < 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            (isValid
                    ? (isExpiringSoon ? Colors.amber : Colors.green)
                    : Colors.red)
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isValid ? (isExpiringSoon ? '${daysLeft}d left' : 'Valid') : 'Expired',
        style: TextStyle(
          color: isValid
              ? (isExpiringSoon ? Colors.amber : Colors.greenAccent)
              : Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionsCell(Battery b) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIcon(
          Icons.info_outline_rounded,
          Colors.white54,
          'Detail',
          () => _openDetailDrawer(b),
        ),
        _actionIcon(
          Icons.edit_note_rounded,
          Colors.blueAccent.withValues(alpha: 0.7),
          'Edit',
          () => _openEditDrawer(b),
        ),
        _actionIcon(
          Icons.block_rounded,
          Colors.redAccent.withValues(alpha: 0.7),
          'Retire',
          () => _confirmDelete(b),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.white38),
          color: const Color(0xFF1E293B),
          onSelected: (val) {
            if (val == 'qr') _viewQR(b);
            if (val == 'copy') {
              Clipboard.setData(ClipboardData(text: b.serialNumber));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Serial copied')));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'qr',
              child: Row(
                children: [
                  Icon(Icons.qr_code, size: 16, color: Colors.white54),
                  SizedBox(width: 8),
                  Text('QR Code', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16, color: Colors.white54),
                  SizedBox(width: 8),
                  Text('Copy Serial', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionIcon(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }

  // =========================================================================
  // BULK ACTION BAR
  // =========================================================================
  Widget _buildBulkActionBar() {
    return AnimatedBuilder(
      animation: _bulkBarController,
      builder: (context, child) {
        if (_bulkBarController.value == 0) return const SizedBox.shrink();
        return Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 1.5), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: _bulkBarController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearSelection,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const Spacer(),
                  _bulkBtn('Available', const Color(0xFF22C55E)),
                  const SizedBox(width: 8),
                  _bulkBtn('Maintenance', const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _bulkBtn('Retired', const Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _exportInventory(),
                    icon: const Icon(
                      Icons.download,
                      size: 16,
                      color: Colors.white54,
                    ),
                    label: const Text(
                      'Export',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bulkBtn(String status, Color color) {
    return ElevatedButton(
      onPressed: () => _bulkChangeStatus(status.toLowerCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // =========================================================================
  // PAGINATION
  // =========================================================================
  Widget _buildPagination() {
    final int totalPages = (_totalCount / _rowsPerPage).ceil();
    final int start = _currentPage * _rowsPerPage + 1;
    final int end = (start + _rowsPerPage - 1).clamp(0, _totalCount);

    if (_totalCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Text(
            'Showing $start–$end of $_totalCount batteries',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const Spacer(),
          // Page buttons
          ...List.generate(totalPages.clamp(0, 7), (i) {
            final pageIndex = i;
            final isCurrentPage = pageIndex == _currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  setState(() => _currentPage = pageIndex);
                  _loadData();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pageIndex + 1}',
                    style: TextStyle(
                      color: isCurrentPage ? Colors.white : Colors.white38,
                      fontWeight: isCurrentPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 16),
          // Rows per page
          const Text(
            'Rows:',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _rowsPerPage,
                items: [20, 50, 100]
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text('$e', style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _rowsPerPage = v!;
                    _currentPage = 0;
                  });
                  _loadData();
                },
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }
}
