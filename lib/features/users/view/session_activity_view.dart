import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/audit_log.dart';
import '../data/repositories/audit_log_repository.dart';
import '../provider/user_provider.dart';
import '../provider/audit_provider.dart';
import '../../auth/provider/session_provider.dart';
import '../../auth/data/models/user_session.dart';

class SessionActivityView extends ConsumerStatefulWidget {
  const SessionActivityView({super.key});

  @override
  ConsumerState<SessionActivityView> createState() => _SessionActivityViewState();
}

class _SessionActivityViewState extends ConsumerState<SessionActivityView> with SingleTickerProviderStateMixin {
  late AuditLogRepository _repository;
  late final TabController _tabController = TabController(length: 2, vsync: this);
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String _actionFilter = 'all';
  String _moduleFilter = 'all';
  List<String> _actionTypes = [];
  List<String> _modules = [];

  @override
  void initState() {
    super.initState();
    _repository = ref.read(auditLogRepositoryProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final logs = await _repository.getLogs(
      action: _actionFilter == 'all' ? null : _actionFilter,
      module: _moduleFilter == 'all' ? null : _moduleFilter,
    );
    final actions = await _repository.getActionTypes();
    final modules = await _repository.getModules();
    setState(() {
      _logs = logs;
      _actionTypes = actions;
      _modules = modules;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final repo = ref.read(auditRepositoryProvider);
    final actions = await repo.getActionTypes();
    final modules = await repo.getModules();
    if (mounted) {
      setState(() {
        _actionTypes = actions;
        _modules = modules;
      });
    }
    _refreshAudit();
  }

  void _refreshAudit() {
    ref.read(auditProvider.notifier).loadLogs(
      action: _actionFilter == 'all' ? null : _actionFilter,
      module: _moduleFilter == 'all' ? null : _moduleFilter,
    );
  }

  void _refreshSessions() {
    // ref.read(sessionProvider.notifier).loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.white38,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: 'Active Sessions'),
                  Tab(text: 'Audit Logs'),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _tabController.index == 0 ? _refreshSessions() : _refreshAudit(),
                icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveSessionsTab(),
              _buildAuditLogsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionsTab() {
    // final sessionState = ref.watch(sessionProvider);
    final sessions = [];

    if (sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    /*
    if (sessionState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: ${sessionState.error}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshSessions, child: const Text('Retry')),
          ],
        ),
      );
    }
    */

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Active Sessions', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('Review and manage your current login sessions across different devices.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),

          ...sessions.map((session) => _buildSessionItem(session)).toList(),
          
          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No active sessions found.', style: GoogleFonts.inter(color: Colors.white24)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(dynamic session) {
    final isDesktop = session.deviceType.toLowerCase().contains('desktop') || 
                      session.deviceType.toLowerCase().contains('windows') || 
                      session.deviceType.toLowerCase().contains('mac');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: session.isCurrent ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (session.isCurrent ? Colors.blue : Colors.white).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDesktop ? Icons.desktop_windows : Icons.smartphone,
              color: session.isCurrent ? Colors.blue : Colors.white70,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(session.deviceName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    if (session.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Current Device', style: GoogleFonts.inter(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('${session.ipAddress} • Last active: ${DateFormat('MMM d, HH:mm').format(session.lastActiveAt)}', 
                     style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (!session.isCurrent)
            TextButton(
              onPressed: () => _confirmRevoke(session),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withValues(alpha: 0.8)),
              child: const Text('Revoke'),
            ),
        ],
      ),
    );
  }

  void _confirmRevoke(dynamic session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Revoke Session?', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('Are you sure you want to terminate the session on ${session.deviceName}? You will be logged out from that device.',
                     style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // ref.read(sessionProvider.notifier).revokeSession(session.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Session revoked: ${session.deviceName}'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Revoke', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    final auditState = ref.watch(auditProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Session Activity Logs', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              
              OutlinedButton.icon(
                onPressed: () async {
                  final success = await ref.read(auditRepositoryProvider).exportLogs(
                    action: _actionFilter,
                    module: _moduleFilter,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Audit log export triggered. You will receive an email shortly.' : 'Export failed. Please try again later.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download, size: 16),
                label: Text('Export', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary cards
          Row(
            children: [
              _buildMiniCard('Total Events', auditState.logs.length.toString(), Icons.list_alt, Colors.blue),
              const SizedBox(width: 12),
              _buildMiniCard('Logins', auditState.logs.where((l) => l.action == 'login').length.toString(), Icons.login, Colors.green),
              const SizedBox(width: 12),
              _buildMiniCard('Modifications', auditState.logs.where((l) => ['update', 'create', 'delete'].contains(l.action)).length.toString(), Icons.edit_note, Colors.amber),
              const SizedBox(width: 12),
              _buildMiniCard('Security', auditState.logs.where((l) => ['suspend', 'permission_change'].contains(l.action)).length.toString(), Icons.shield_outlined, Colors.red),
            ],
          ),
          const SizedBox(height: 20),

          // Filters
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Filters:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              const SizedBox(width: 12),
              _buildDropdownFilter('Action', _actionFilter, _actionTypes, (v) {
                setState(() => _actionFilter = v);
                _refreshAudit();
              }),
              const SizedBox(width: 12),
              _buildDropdownFilter('Module', _moduleFilter, _modules, (v) {
                setState(() => _moduleFilter = v);
                _refreshAudit();
              }),
              
              Text('${auditState.logs.length} events', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Activity log
          if (auditState.isLoading && auditState.logs.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (auditState.error != null)
            Center(
              child: Column(
                children: [
                   const Icon(Icons.error_outline, color: Colors.red, size: 48),
                   const SizedBox(height: 16),
                   Text('Error: ${auditState.error}', style: const TextStyle(color: Colors.white70)),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: _refreshAudit, child: const Text('Retry')),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: auditState.logs.asMap().entries.map((entry) {
                  final log = entry.value;
                  final isLast = entry.key == auditState.logs.length - 1;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline dot
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getAuditActionColor(log.action).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getAuditActionIcon(log.action), color: _getAuditActionColor(log.action), size: 14),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(log.userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getAuditActionColor(log.action).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(log.actionLabel, style: TextStyle(color: _getAuditActionColor(log.action), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(log.module, style: GoogleFonts.firaCode(color: Colors.white38, fontSize: 10)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(log.details, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),

                        // Timestamp
                        Text(
                          DateFormat('MMM d, HH:mm').format(log.timestamp),
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.expand_more, color: Colors.white38, size: 18),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item == 'all' ? 'All ${label}s' : item.replaceAll('_', ' ')),
          )).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Color _getAuditActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'login': case 'logout': return Colors.blue;
      case 'create': return Colors.green;
      case 'update': return Colors.amber;
      case 'delete': return Colors.red;
      case 'suspend': return Colors.red;
      case 'reactivate': return Colors.green;
      case 'kyc_approve': return Colors.green;
      case 'kyc_reject': return Colors.red;
      case 'permission_change': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getAuditActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login': return Icons.login;
      case 'logout': return Icons.logout;
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit;
      case 'delete': return Icons.delete_outline;
      case 'suspend': return Icons.block;
      case 'reactivate': return Icons.check_circle_outline;
      case 'kyc_approve': return Icons.verified;
      case 'kyc_reject': return Icons.cancel;
      case 'permission_change': return Icons.admin_panel_settings;
      default: return Icons.info_outline;
    }
  }
}
