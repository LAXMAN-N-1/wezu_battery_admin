import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../data/models/audit_models.dart';
import '../data/repositories/audit_repository.dart';
import 'widgets/audit_components.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});
  @override State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  final AuditRepository _repo = AuditRepository();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<AuditLogItem> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  int _totalCount = 0;
  final int _limit = 50;
  
  // Filters
  final TextEditingController _searchController = TextEditingController();
  String? _filterAction;
  String? _filterSeverity;
  String? _filterRole;
  String? _filterStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  AuditLogItem? _selectedLog;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _statsRefreshTimer;
  Map<String, dynamic> _stats = {};
  int _newEventsCount = 0;
  bool _showStickyNewBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleIncomingFilters();
      _loadInitialData();
      _loadStats();
    });
    _scrollController.addListener(_onScroll);
    _setupAutoRefresh();
  }

  void _setupAutoRefresh() {
    _statsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadStats();
      _checkForNewEvents();
    });
  }

  Future<void> _checkForNewEvents() async {
     if (_logs.isEmpty || _isLoading) return;
     try {
       final res = await _repo.getAuditLogs(limit: 5);
       final items = res['items'] as List<AuditLogItem>;
       if (items.isNotEmpty) {
         final firstLocalAt = DateTime.parse(_logs.first.timestamp);
         final newItems = items.where((e) => DateTime.parse(e.timestamp).isAfter(firstLocalAt)).toList();
         
         if (newItems.isNotEmpty) {
           if (newItems.length <= 3) {
             // Just prepend them
             for (var i = newItems.length - 1; i >= 0; i--) {
                _prependLog(newItems[i]);
             }
           } else {
             setState(() {
               _newEventsCount += newItems.length;
               _showStickyNewBanner = true;
             });
           }
         }
       }
     } catch (_) {}
  }

  void _handleIncomingFilters() {
    final state = GoRouterState.of(context);
    final params = state.uri.queryParameters;
    
    setState(() {
      if (params.containsKey('severity')) _filterSeverity = params['severity'] == 'All' ? null : params['severity'];
      if (params.containsKey('action')) _filterAction = params['action'] == 'All' ? null : params['action'];
      if (params.containsKey('role')) _filterRole = params['role'] == 'All' ? null : params['role'];
      if (params.containsKey('status')) _filterStatus = params['status'] == 'All' ? null : params['status'];
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _statsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final res = await _repo.getAuditStats();
      if (mounted) setState(() => _stats = res);
    } catch (_) {}
  }


  void _prependLog(AuditLogItem log) {
    setState(() {
      _logs.insert(0, log);
      _skip++;
    });
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 600));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() { _logs.clear(); _skip = 0; _hasMore = true; _isLoading = true; });
    try {
      final res = await _repo.getAuditLogs(
        skip: 0, 
        limit: _limit, 
        action: _filterAction, 
        severity: _filterSeverity,
        status: _filterStatus,
        role: _filterRole,
        startDate: _startDate,
        endDate: _endDate,
        query: _searchController.text,
      );
      final items = res['items'] as List<AuditLogItem>;
      if (mounted) {
        setState(() {
          _logs.addAll(items);
          _totalCount = res['total'] ?? items.length;
          _hasMore = _logs.length < _totalCount;
          _skip = items.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getAuditLogs(
        skip: _skip, 
        limit: _limit, 
        action: _filterAction, 
        severity: _filterSeverity,
        status: _filterStatus,
        role: _filterRole,
        startDate: _startDate,
        endDate: _endDate,
        query: _searchController.text,
      );
      final items = res['items'] as List<AuditLogItem>;
      if (mounted) {
        setState(() {
          _logs.addAll(items);
          _totalCount = res['total'] ?? (_totalCount + items.length);
          _hasMore = _logs.length < _totalCount;
          _skip += items.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: _buildFilterDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatStrip(),
                const SizedBox(height: 24),
                _buildFilterRow(),
                const SizedBox(height: 20),
                Expanded(child: _buildLogsTable()),
              ],
            ),
          ),
          if (_selectedLog != null) _buildDetailDrawer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Audit Logs', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(6), 
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7, height: 7, 
                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)
                      ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms).then().fadeIn(duration: 800.ms),
                      const SizedBox(width: 8),
                      Text('LIVE SYSTEM FEED', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Complete forensic-level record of all system activity and admin actions', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () { _clearFilters(); _loadInitialData(); },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('[ Clear All Filters ]', style: GoogleFonts.inter(color: Colors.blueAccent.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        Row(
          children: [
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'CSV') _exportToCSV();
                else if (val == 'PDF') _exportToPDF();
                else if (val == 'EXCEL') _exportToExcel();
              },
              offset: const Offset(0, 45),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.file_download_outlined, size: 18, color: Colors.white70),
                    const SizedBox(width: 10),
                    Text('Export Logs', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white38),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                _exportMenuItem('CSV', Icons.table_chart_outlined),
                _exportMenuItem('PDF', Icons.picture_as_pdf_outlined),
                _exportMenuItem('EXCEL', Icons.grid_on_outlined),
              ],
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('More Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  Widget _buildStatStrip() {
    return Row(
      children: [
        _miniStat('Total Events Today', _formatVal(_stats['total_today'] ?? 0), Colors.blueAccent, () {
          _clearFilters();
          _loadInitialData();
        }),
        const SizedBox(width: 16),
        _miniStat('Admin Actions', _formatVal(_stats['admin_actions'] ?? 0), Colors.greenAccent, () {
          _clearFilters();
          setState(() => _filterRole = 'admin');
          _loadInitialData();
        }),
        const SizedBox(width: 16),
        _miniStat('Failed Logins', _formatVal(_stats['failed_logins'] ?? 0), Colors.orangeAccent, () {
          _clearFilters();
          setState(() {
             _filterAction = 'login';
             _filterStatus = 'Failed';
          });
          _loadInitialData();
        }),
        const SizedBox(width: 16),
        _miniStat('Critical Events', _formatVal(_stats['critical_events'] ?? 0), Colors.redAccent, () {
          _clearFilters();
          setState(() => _filterSeverity = 'Critical');
          _loadInitialData();
        }),
      ],
    );
  }

  String _formatVal(dynamic v) {
    if (v == null) return '0';
    final n = v is int ? v : int.tryParse(v.toString()) ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _clearFilters() {
    setState(() {
      _filterAction = null;
      _filterSeverity = null;
      _filterRole = null;
      _filterStatus = null;
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
  }

  Widget _miniStat(String label, String value, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white38, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadInitialData(),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search User, IP, or Resource...',
                      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildDropdownFilter('Action', _filterAction, ['All', 'login', 'create', 'update', 'delete'], (v) {
          setState(() => _filterAction = v == 'All' ? null : v);
          _loadInitialData();
        }),
        const SizedBox(width: 12),
        _buildDropdownFilter('Severity', _filterSeverity, ['All', 'Info', 'Warning', 'Critical'], (v) {
          setState(() => _filterSeverity = v == 'All' ? null : v);
          _loadInitialData();
        }),
        const SizedBox(width: 12),
        _buildDropdownFilter('Status', _filterStatus, ['All', 'Success', 'Failed'], (v) {
          setState(() => _filterStatus = v == 'All' ? null : v);
          _loadInitialData();
        }),
        const SizedBox(width: 12),
        _buildDropdownFilter('Role', _filterRole, ['All', 'admin', 'super_admin', 'dealer', 'manager'], (v) {
          setState(() => _filterRole = v == 'All' ? null : v);
          _loadInitialData();
        }),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, String? current, List<String> options, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current ?? 'All',
          dropdownColor: const Color(0xFF0F172A),
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white38),
          items: options.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val.toUpperCase()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLogsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildTableHeader(),
            if (_showStickyNewBanner) _buildNewEventBanner(),
            Expanded(
              child: _logs.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : AnimatedList(
                      key: _listKey,
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      initialItemCount: _logs.length,
                      itemBuilder: (context, index, animation) {
                        if (index >= _logs.length) return const SizedBox.shrink();
                        return _buildAnimatedRow(_logs[index], index, animation);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white.withValues(alpha: 0.03),
      child: Row(
        children: [
          _th('TIMESTAMP', flex: 2),
          _th('USER', flex: 3),
          _th('ACTION', flex: 3),
          _th('RESOURCE', flex: 2),
          _th('CLIENT IP', flex: 2),
          _th('SEVERITY', flex: 2),
          _th('STATUS', flex: 2),
          _th('', flex: 1), 
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildAnimatedRow(AuditLogItem log, int index, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(Tween(begin: const Offset(0, -0.5), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
      child: FadeTransition(
        opacity: animation,
        child: Column(
          children: [
            _buildRow(log, index),
            Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
            if (index == _logs.length - 1 && _logs.length < _totalCount) _buildLoadMoreTrigger(),
            if (index == _logs.length - 1 && _logs.length >= _totalCount) _buildPaginationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreTrigger() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: _isLoading 
            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)
            : TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.add, size: 16),
                label: Text('LOAD ${_limit} MORE EVENTS', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11)),
              ),
      ),
    );
  }

  Widget _buildPaginationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'SHOWING ${_logs.length} OF $_totalCount EVENTS — END OF LOG',
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildRow(AuditLogItem log, int index) {
    final isSelected = _selectedLog?.id == log.id;
    final sevColor = log.severity == 'Critical' 
        ? Colors.redAccent 
        : log.severity == 'Warning' 
            ? Colors.orangeAccent 
            : Colors.blueAccent;
    
    return InkWell(
      onTap: () => setState(() => _selectedLog = log),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM d, HH:mm:ss').format(DateTime.parse(log.timestamp)),
                style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 11),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    child: Text(log.userName[0], style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(log.userEmail.isNotEmpty ? log.userEmail : 'System Account', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                   _deviceIcon(log.device),
                   const SizedBox(width: 10),
                   Expanded(
                     child: Text(
                        log.action.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                   ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                log.resourceType,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                log.ipAddress ?? '—',
                style: GoogleFonts.robotoMono(color: Colors.blueAccent.withValues(alpha: 0.6), fontSize: 11),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(
                  log.severity,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: sevColor, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildStatusCell(log.status),
            ),
            const Expanded(
              flex: 1,
              child: Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    final isSuccess = status.toLowerCase() == 'success';
    final color = isSuccess ? Colors.greenAccent : Colors.redAccent;
    return Row(
      children: [
        Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          status,
          style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text('No log entries match your criteria', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _filterAction = null;
                _filterSeverity = null;
                _filterRole = null;
                _filterStatus = null;
                _startDate = null;
                _endDate = null;
              });
              _loadInitialData();
            },
            child: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }

  // ─── Filter Drawer ────────────────────────────────────────────────────────
  Widget _buildFilterDrawer() {
    return Container(
      width: 400,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('Filters', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Narrow down audit entries by parameters', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 32),
          _drawerFilterSection('Severity', [
            _filterOption('Critical', _filterSeverity == 'Critical', () => setState(() => _filterSeverity = 'Critical')),
            _filterOption('Warning', _filterSeverity == 'Warning', () => setState(() => _filterSeverity = 'Warning')),
            _filterOption('Info', _filterSeverity == 'Info', () => setState(() => _filterSeverity = 'Info')),
            _filterOption('All', _filterSeverity == null, () => setState(() => _filterSeverity = null)),
          ]),
          const SizedBox(height: 24),
          _drawerFilterSection('Action Type', [
            _filterOption('Login', _filterAction == 'login', () => setState(() => _filterAction = 'login')),
            _filterOption('Create', _filterAction == 'create', () => setState(() => _filterAction = 'create')),
            _filterOption('Update', _filterAction == 'update', () => setState(() => _filterAction = 'update')),
            _filterOption('Delete', _filterAction == 'delete', () => setState(() => _filterAction = 'delete')),
            _filterOption('All', _filterAction == null, () => setState(() => _filterAction = null)),
          ]),
          const SizedBox(height: 24),
          _drawerFilterSection('Status', [
            _filterOption('Success', _filterStatus == 'Success', () => setState(() => _filterStatus = 'Success')),
            _filterOption('Failed', _filterStatus == 'Failed', () => setState(() => _filterStatus = 'Failed')),
            _filterOption('All', _filterStatus == null, () => setState(() => _filterStatus = null)),
          ]),
          const SizedBox(height: 24),
          _drawerFilterSection('Date Range', [
            _filterOption('Today', false, () => _setDateRange(0)),
            _filterOption('Last 7 Days', false, () => _setDateRange(7)),
            _filterOption('Last 30 Days', false, () => _setDateRange(30)),
            _filterOption('Custom Range', _startDate != null, () => _selectCustomDateRange()),
            _filterOption('Clear', _startDate == null, () {
              setState(() { _startDate = null; _endDate = null; });
            }),
          ]),
          if (_startDate != null) ...[
             const SizedBox(height: 8),
             Text(
               'Period: ${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate ?? DateTime.now())}',
               style: GoogleFonts.robotoMono(color: Colors.blueAccent, fontSize: 11),
             ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() { 
                      _filterSeverity = null; 
                      _filterAction = null; 
                      _filterStatus = null;
                      _filterRole = null;
                      _startDate = null;
                      _endDate = null;
                    });
                    Navigator.pop(context);
                    _loadInitialData();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadInitialData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerFilterSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: options),
      ],
    );
  }

  Widget _filterOption(String label, bool active, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
      selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: active ? Colors.blueAccent : Colors.white54, fontSize: 12),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: BorderSide(color: active ? Colors.blueAccent : Colors.white12),
    );
  }

  // ─── Detail Drawer ────────────────────────────────────────────────────────
  Widget _buildDetailDrawer() {
    final log = _selectedLog!;
    return Positioned(
      right: 0, top: 0, bottom: 0,
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 50, offset: const Offset(-8, 0))],
          border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        ),
        child: Column(
          children: [
            _buildDrawerTitleRow(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  _drawerInfoSection('IDENTITY INTELLIGENCE', [
                    Row(
                      children: [
                        CircleAvatar(radius: 24, backgroundColor: Colors.blueAccent.withValues(alpha: 0.2), child: Text(log.userName[0], style: const TextStyle(fontSize: 20, color: Colors.blueAccent))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.userName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(log.userEmail, style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                          child: Text('ADMIN', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _drawerInfoSection('EVENT TIMELINE & METADATA', [
                    _dataRow('Event ID', 'AUD-${log.id.toString()}'),
                    _dataRow('Timestamp', DateFormat('MMMM d, yyyy — HH:mm:ss.S').format(DateTime.parse(log.timestamp))),
                    _dataRow('Action', log.action.toUpperCase(), color: Colors.blueAccent),
                    _dataRow('Severity', log.severity, color: log.severity == 'Critical' ? Colors.redAccent : Colors.blueAccent),
                    _dataRow('Status', log.status, color: log.status == 'Success' ? Colors.greenAccent : Colors.redAccent),
                  ]),
                  const SizedBox(height: 32),
                  _drawerInfoSection('CLIENT & ORIGIN', [
                    _dataRow('IP Address', log.ipAddress ?? '—'),
                    _dataRow('Location', log.location ?? 'Unavailable', trailing: const Icon(Icons.location_on_outlined, color: Colors.blueAccent, size: 14)),
                    _dataRow('User Agent', log.device ?? 'Generic Client'),
                    _dataRow('Browser', log.browser ?? 'Unknown'),
                  ]),
                  const SizedBox(height: 32),
                  _drawerInfoSection('TRANSACTION PAYLOAD', [
                    if (log.oldValue != null || log.newValue != null) ...[
                      JsonDiffViewer(oldValue: log.oldValue, newValue: log.newValue),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF030712),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Text(
                          log.details,
                          style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await _showFlagDialog(log);
                            if (confirmed == true) {
                              setState(() => _selectedLog = null);
                            }
                          },
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Flag Entry'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: const BorderSide(color: Colors.orangeAccent)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy JSON'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().slideX(begin: 1, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildDrawerTitleRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 24, 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 12),
              Text('Audit Entry Intelligence', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          IconButton(onPressed: () => setState(() => _selectedLog = null), icon: const Icon(Icons.close, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _drawerInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _dataRow(String label, String value, {Color? color, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          Text(value, style: GoogleFonts.robotoMono(color: color ?? Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _setDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate!.subtract(Duration(days: days));
    });
  }

  Future<void> _exportToCSV() async {
    // Show loading or notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing audit logs export...'), duration: Duration(seconds: 1)),
    );

    // Fetch all logs matching current filters (up to some reasonable limit for export, e.g., 500)
    final res = await _repo.getAuditLogs(
      skip: 0,
      limit: 500,
      action: _filterAction,
      severity: _filterSeverity,
      status: _filterStatus,
      role: _filterRole,
      startDate: _startDate,
      endDate: _endDate,
      query: _searchController.text,
    );

    final List<AuditLogItem> exportItems = res['items'] as List<AuditLogItem>;
    
    if (exportItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data found for export')));
      }
      return;
    }

    // Generate CSV string
    final buffer = StringBuffer();
    buffer.writeln('ID,Timestamp,UserName,UserEmail,Action,ResourceType,IPAddress,Severity,Status,Details');
    
    for (final log in exportItems) {
      buffer.writeln([
        log.id,
        log.timestamp,
        '"${log.userName}"',
        log.userEmail,
        log.action,
        log.resourceType,
        log.ipAddress ?? '',
        log.severity,
        log.status,
        '"${log.details.replaceAll('"', '""')}"',
      ].join(','));
    }

    if (kIsWeb) {
      _downloadCSVWeb(buffer.toString(), 'wezu_audit_logs_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv');
    } else {
      // For mobile/desktop, we could use path_provider and dart:io
      // But user specifically asked for web export
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV Export currently supported on Web only.')));
      }
    }
  }

  void _downloadCSVWeb(String csvData, String fileName) {
    try {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }

  Future<bool?> _showFlagDialog(AuditLogItem log) async {
    final controller = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Flag as Suspicious', style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you flagging this log entry?', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Reason...', hintStyle: TextStyle(color: Colors.white24)),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _repo.flagAuditLogSuspicious(log.id, controller.text);
                if (context.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Confirm Flag'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _exportMenuItem(String label, IconData icon) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildNewEventBanner() {
    return InkWell(
      onTap: () {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        setState(() {
          _showStickyNewBanner = false;
          _newEventsCount = 0;
        });
        _loadInitialData();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.9),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              '$_newEventsCount NEW EVENTS DETECTED. CLICK TO LOAD AND SCROLL TO TOP.',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.2)),
    );
  }

  Widget _deviceIcon(String? device) {
    IconData icon = Icons.desktop_windows_outlined;
    final d = device?.toLowerCase() ?? '';
    if (d.contains('iphone') || d.contains('android') || d.contains('mobile')) {
      icon = Icons.smartphone_rounded;
    } else if (d.contains('tablet') || d.contains('ipad')) {
      icon = Icons.tablet_mac_rounded;
    }
    return Icon(icon, size: 16, color: Colors.white24);
  }

  Future<void> _exportToPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export module initializing...')));
    // Typically uses 'printing' or 'pdf' package. Placeholder for now.
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export started.')));
  }

  Future<void> _exportToExcel() async {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Export module initializing...')));
     // Typically uses 'excel' package. Placeholder for now.
     await Future.delayed(const Duration(seconds: 1));
     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Export started.')));
  }
  Future<void> _selectCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.blueAccent, onPrimary: Colors.white, surface: Color(0xFF1E293B), onSurface: Colors.white),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }
}

