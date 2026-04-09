import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../data/models/audit_models.dart';
import '../data/providers/audit_logs_provider.dart';
import '../data/providers/audit_dashboard_provider.dart';
import '../widgets/json_diff_viewer.dart';
import '../data/repositories/audit_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class AuditLogsView extends ConsumerStatefulWidget {
  const AuditLogsView({super.key});

  @override
  ConsumerState<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends ConsumerState<AuditLogsView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Handle initial query parameters from dashboard navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final state = GoRouterState.of(context);
        final severity = state.uri.queryParameters['severity'];
        final action = state.uri.queryParameters['action'];
        final id = state.uri.queryParameters['id'];

        if (severity != null) {
          ref.read(auditLogsProvider.notifier).setFilterSeverity(severity);
        }
        if (action != null) {
          ref.read(auditLogsProvider.notifier).setFilterAction(action);
        }
        if (id != null) ref.read(auditLogsProvider.notifier).setSearch(id);
      } catch (e) {
        debugPrint('GoRouterState error in AuditLogsView: $e');
      }
    });
  }

  void _checkAndShowSpecificLog(AuditLogsState state) {
    if (!mounted) return;
    try {
      final routerState = GoRouterState.of(context);
      final idStr = routerState.uri.queryParameters['id'];
      if (idStr != null && state.logs.isNotEmpty && !state.isLoading) {
        final id = int.tryParse(idStr);
        if (id != null) {
          final log = state.logs.where((l) => l.id == id).firstOrNull;
          if (log != null) {
            // Check if already showing this log to avoid infinite loop
            // For now, we'll just show it once
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _showLogDetails(log);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking specific log: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {}); // Trigger rebuild for FAB visibility
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditLogsProvider.notifier).loadLogs(refresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogsProvider);

    // Watch for specific log ID in URL and open if it matches
    ref.listen<AuditLogsState>(auditLogsProvider, (prev, curr) {
      if (prev?.isLoading == true && curr.isLoading == false) {
        _checkAndShowSpecificLog(curr);
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      endDrawer: _buildFilterDrawer(),
      floatingActionButton: _scrollController.hasClients && _scrollController.offset > 300 
          ? FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(0, duration: 500.ms, curve: Curves.easeOut),
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            )
          : null,
      body: Column(
        children: [
          _buildHeader(state),
          _buildFilterBar(state),
          _buildActiveFilters(state),
          Expanded(
            child: Stack(
              children: [
                state.error != null
                    ? _buildErrorState(state.error!)
                    : state.isLoading && state.logs.isEmpty
                        ? _buildSkeleton()
                        : state.logs.isEmpty 
                            ? _buildEmptyState()
                            : _buildScrollableTable(state),
                if (state.newLogIds.isNotEmpty && !state.isLoading)
                  _buildNewEventsBanner(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewEventsBanner(AuditLogsState state) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: InkWell(
          onTap: () {
            _scrollController.animateTo(0, duration: 600.ms, curve: Curves.easeOutQuart);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 12),
                Text(
                  '${state.newLogIds.length} NEW EVENTS',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                ),
              ],
            ),
          ).animate().slideY(begin: -2.0, end: 0.0),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(24),
      itemBuilder: (context, index) => Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(duration: 1.5.seconds, color: Colors.blue.withValues(alpha: 0.05)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'No matching audit records found',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search query.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white24),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => ref.read(auditLogsProvider.notifier).clearFilters(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset All Filters'),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuditLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.end,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Audit Logs',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(child: _buildLiveBadge()),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Complete forensic-level record of all system activity and admin actions',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
          _buildActionHeaderButtons(),
        ],
      ),
    );
  }

  Widget _buildActionHeaderButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _handleExport('csv'),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Advanced Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 800.ms).fadeOut(),
          const SizedBox(width: 8),
          Text(
            'LIVE SYSTEM FEED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _handleExport(String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating ${type.toUpperCase()} report...'),
        backgroundColor: Colors.blue,
      ),
    );
    
    try {
      final repo = ref.read(auditRepositoryProvider);
      final url = await repo.exportAuditLogs(format: type);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated: $url'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                // In a real app, use Clipboard.setData
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildActiveFilters(AuditLogsState state) {
    if (!_hasActiveFilters(state)) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Text(
            'APPLIED:',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white24,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (state.filterSeverity != null)
                  _filterChip(
                    'Severity: ${state.filterSeverity!.toUpperCase()}',
                    Colors.orange,
                    () => ref.read(auditLogsProvider.notifier).setFilterSeverity(null),
                  ),
                if (state.filterStatus != null)
                  _filterChip(
                    'Status: ${state.filterStatus!.toUpperCase()}',
                    Colors.green,
                    () => ref.read(auditLogsProvider.notifier).setFilterStatus(null),
                  ),
                if (state.filterAction != null)
                  _filterChip(
                    'Module: ${state.filterAction}',
                    Colors.blue,
                    () => ref.read(auditLogsProvider.notifier).setFilterAction(null),
                  ),
                if (state.search != null && state.search!.isNotEmpty)
                  _filterChip(
                    'Search: "${state.search}"',
                    Colors.purple,
                    () => ref.read(auditLogsProvider.notifier).setSearch(null),
                  ),
                if (state.dateRange != null)
                   _filterChip(
                    'Time Range',
                    Colors.teal,
                    () => ref.read(auditLogsProvider.notifier).setDateRange(null),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(auditLogsProvider.notifier).clearFilters(),
            child: Text(
              'CLEAR ALL',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(AuditLogsState state) {
    return state.filterSeverity != null ||
        state.filterStatus != null ||
        state.filterAction != null ||
        (state.search != null && state.search!.isNotEmpty) ||
        state.dateRange != null;
  }

  Widget _filterChip(String label, Color color, VoidCallback onDeleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: Icon(Icons.close, size: 12, color: color.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AuditLogsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                onChanged: (v) => ref.read(auditLogsProvider.notifier).setSearch(v),
                decoration: InputDecoration(
                  hintText: 'Search by User, Action, Resource ID, or Client IP...',
                  hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Checkbox(
              value: false,
              onChanged: (v) {},
              side: const BorderSide(color: Colors.white24),
            ),
          ),
          _columnHeader('TIMESTAMP', 140),
          const SizedBox(width: 16),
          _columnHeader('USER', 260),
          _columnHeader('ACTION PERFORMED', 400),
          _columnHeader('MODULE', 140),
          _columnHeader('IP ADDRESS', 140),
          _columnHeader('DEVICE', 100),
          _columnHeader('SEVERITY', 120),
          _columnHeader('STATUS', 120),
          _columnHeader('FORENSICS', 114),
        ],
      ),
    );
  }

  Widget _columnHeader(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildScrollableTable(AuditLogsState state) {
    if (state.logs.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              'No events found matching filters.',
              style: GoogleFonts.inter(color: Colors.white38),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(auditLogsProvider.notifier).clearFilters(),
              child: const Text('Clear Filters', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1650, // 1590 (columns) + 60 (padding/buffer)
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        _buildTableHeader(),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: state.logs.length + (state.isMoreLoading ? 1 : 0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              if (index == state.logs.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final log = state.logs[index];
                              return _buildLogRow(log, index);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildPaginationFooter(state),
      ],
    );
  }



  Widget _buildLogRow(AuditLogItem log, int index) {
    final severityColor = log.severity == 'critical'
        ? const Color(0xFFEF4444)
        : log.severity == 'warning'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);
    
    final statusColor = log.status == 'success' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return InkWell(
      onTap: () => _showLogDetails(log),
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: log.isSuspicious
              ? Colors.orange.withValues(alpha: 0.1)
              : index.isEven
              ? Colors.white.withValues(alpha: 0.01)
              : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Checkbox(
                value: false,
                onChanged: (v) {},
                side: const BorderSide(color: Colors.white24),
              ),
            ),
            SizedBox(
              width: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    DateFormat('MMM d, yyyy').format(DateTime.parse(log.timestamp)),
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('HH:mm:ss').format(DateTime.parse(log.timestamp)),
                    style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white24),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 260,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: log.userAvatar.isNotEmpty ? DecorationImage(image: NetworkImage(log.userAvatar), fit: BoxFit.cover) : null,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    ),
                    child: log.userAvatar.isEmpty 
                         ? Center(child: Text(log.userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))) 
                         : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.userName,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          log.userEmail,
                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 400,
              child: Text(
                log.action,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                log.module,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                log.ipAddress ?? '—',
                style: GoogleFonts.robotoMono(color: const Color(0xFF3B82F6).withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
             SizedBox(
              width: 100,
              child: Icon(
                (log.userAgent?.toLowerCase().contains('mobile') ?? false) ? Icons.smartphone : Icons.laptop,
                color: Colors.white.withValues(alpha: 0.2),
                size: 18,
              ),
            ),
            SizedBox(
              width: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Center(
                  child: Text(
                    log.severity.toUpperCase(), 
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: severityColor)
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    log.status == 'success' ? 'Success' : 'Failed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 114,
              child: AdminButton(
                 label: 'Details',
                 width: 100,
                 height: 36,
                 onPressed: () => _showLogDetails(log),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showLogDetails(AuditLogItem log) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ForensicDetail',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) => Align(
        alignment: Alignment.centerRight,
        child: _buildLogDetailsSidebar(log, dialogContext),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildLogDetailsSidebar(AuditLogItem log, BuildContext dialogContext) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 480,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(left: BorderSide(color: Colors.white10)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 10)],
        ),
        child: Column(
          children: [
            _buildSidebarHeader(log, dialogContext),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _sidebarSectionLabel('METADATA_SUMMARY'),
                     const SizedBox(height: 24),
                     _metadataRow('Event ID', 'LOG-2026-${log.id.toString().padLeft(5, '0')}', Icons.fingerprint),
                     _metadataRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.parse(log.timestamp)), Icons.schedule),
                     const SizedBox(height: 48),
                     _sidebarSectionLabel('USER_IDENTITY'),
                     const SizedBox(height: 24),
                     _buildUserDetailsCard(log),
                     const SizedBox(height: 48),
                     _sidebarSectionLabel('ACTION_INTELLIGENCE'),
                     const SizedBox(height: 24),
                     _buildActionIntelligence(log),
                     const SizedBox(height: 48),
                     _sidebarSectionLabel('DATA_HISTORICAL_DIFF'),
                     const SizedBox(height: 24),
                     SizedBox(
                       height: 300,
                       child: JsonDiffViewer(
                         oldValue: log.oldValue,
                         newValue: log.newValue,
                       ),
                     ),
                     const SizedBox(height: 48),
                     _buildSuspiciousFlagButton(log),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(AuditLogItem log, BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_rounded, color: Colors.blueAccent),
          const SizedBox(width: 16),
          Text(
            'Log Details',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            },
            icon: const Icon(Icons.close, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _metadataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white24),
          const SizedBox(width: 12),
          Text('$label:', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUserDetailsCard(AuditLogItem log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: log.userAvatar.isNotEmpty ? NetworkImage(log.userAvatar) : null,
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
            child: log.userAvatar.isEmpty ? Text(log.userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.userName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(log.userEmail, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('SUPER ADMIN', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIntelligence(AuditLogItem log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(log.action, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Updated user role from Staff to Admin for user ref:#78291. Verification sequence complete.',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 32),
        Row(
           children: [
             Expanded(child: _miniStat('Module', log.module, Icons.apps)),
             Expanded(child: _miniStat('IP Address', log.ipAddress ?? '—', Icons.language)),
           ],
        ),
        const SizedBox(height: 20),
        Row(
           children: [
             Expanded(child: _miniStat('Device', 'Windows 11 Desktop', Icons.laptop)),
             Expanded(child: _miniStat('Browser', 'Chrome 123.0.x', Icons.web)),
           ],
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           children: [
             Icon(icon, size: 12, color: Colors.white24),
             const SizedBox(width: 8),
             Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
           ],
         ),
         const SizedBox(height: 4),
         Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
       ],
     );
  }

  Widget _buildSuspiciousFlagButton(AuditLogItem log) {
    return InkWell(
      onTap: () {
         ref.read(auditLogsProvider.notifier).toggleSuspicious(log.id);
         if (Navigator.canPop(context)) Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(log.isSuspicious ? 'Flag removed' : 'Event flagged as suspicious'),
             backgroundColor: Colors.orangeAccent,
           ),
         );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: log.isSuspicious ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.05),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(log.isSuspicious ? Icons.flag : Icons.flag_outlined, color: Colors.orangeAccent, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.isSuspicious ? 'Flagged as Suspicious' : 'Flag as Suspicious', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(log.isSuspicious ? 'This event is marked for high-priority review.' : 'Add this event to the high-priority review queue.', style: GoogleFonts.inter(color: Colors.orangeAccent.withValues(alpha: 0.6), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.firaCode(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent.withValues(alpha: 0.6), letterSpacing: 1.5),
    );
  }

  Widget _buildPaginationFooter(AuditLogsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(
            'Showing 1-50 of 4,832 events',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
          ),
          const Spacer(),
          _paginationBtn(Icons.chevron_left, false),
          const SizedBox(width: 12),
          _paginationNum('1', true),
          _paginationNum('2', false),
          _paginationNum('3', false),
          const Text('...', style: TextStyle(color: Colors.white24)),
          _paginationNum('97', false),
          const SizedBox(width: 12),
          _paginationBtn(Icons.chevron_right, true),
        ],
      ),
    );
  }

  Widget _paginationBtn(IconData icon, bool enabled) {
    return IconButton(
      onPressed: enabled ? () {} : null,
      icon: Icon(icon, color: enabled ? Colors.white70 : Colors.white10),
      constraints: const BoxConstraints(),
    );
  }

  Widget _paginationNum(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
            border: active ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              color: active ? Colors.blueAccent : Colors.white38,
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    final state = ref.watch(auditLogsProvider);
    return Container(
      width: 320,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'Advanced Filters',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _drawerSectionLabel('DATE RANGE'),
          const SizedBox(height: 8),
          _buildDateRangeButton(state),
          const SizedBox(height: 24),
          _drawerSectionLabel('SEVERITY'),
          const SizedBox(height: 8),
          _buildDrawerDropdown(
            ['INFO', 'WARNING', 'CRITICAL'],
            state.filterSeverity?.toUpperCase(),
            (v) => ref.read(auditLogsProvider.notifier).setFilterSeverity(v?.toLowerCase()),
          ),
          const SizedBox(height: 24),
          _drawerSectionLabel('STATUS'),
          const SizedBox(height: 8),
          _buildDrawerDropdown(
            ['SUCCESS', 'FAILED'],
            state.filterStatus?.toUpperCase(),
            (v) => ref.read(auditLogsProvider.notifier).setFilterStatus(v?.toLowerCase()),
          ),
          const SizedBox(height: 24),
          _drawerSectionLabel('RESOURCE'),
          const SizedBox(height: 8),
          _buildDrawerDropdown(
            ['CMS', 'SECURITY', 'USER MGMT', 'FINANCE'],
            state.filterAction?.toUpperCase(), // Reusing filterAction for module for now or we could add a module filter
            (v) => ref.read(auditLogsProvider.notifier).setFilterAction(v),
          ),
          const Spacer(),
          AdminButton(
            label: 'Apply Filters',
            onPressed: () {
               if (Navigator.canPop(context)) {
                 Navigator.pop(context);
               }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(auditLogsProvider.notifier).clearFilters();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Center(
              child: Text(
                'Clear All Filters',
                style: TextStyle(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDateRangeButton(AuditLogsState state) {
    String label = 'Select Range';
    if (state.dateRange != null) {
      label = '${DateFormat('MMM d').format(state.dateRange!.start)} - ${DateFormat('MMM d').format(state.dateRange!.end)}';
    }
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2025),
          lastDate: DateTime.now(),
          initialDateRange: state.dateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF3B82F6),
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E293B),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          ref.read(auditLogsProvider.notifier).setDateRange(range);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.white38),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerDropdown(List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          dropdownColor: const Color(0xFF1E293B),
          isExpanded: true,
          value: value,
          hint: const Text('All', style: TextStyle(color: Colors.white24, fontSize: 13)),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            ...items.map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
          const SizedBox(height: 24),
          Text(
            'Failed to load audit logs',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AdminButton(
            label: 'Retry Connection',
            width: 200,
            onPressed: () => ref.read(auditLogsProvider.notifier).loadLogs(),
          ),
        ],
      ),
    );
  }
}

