import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/audit_log.dart';
import '../data/repositories/audit_log_repository.dart';
import '../provider/audit_provider.dart';

class SessionActivityView extends ConsumerStatefulWidget {
  const SessionActivityView({super.key});

  @override
  ConsumerState<SessionActivityView> createState() => _SessionActivityViewState();
}

class _SessionActivityViewState extends ConsumerState<SessionActivityView> {
  String _actionFilter = 'all';
  String _moduleFilter = 'all';
  List<String> _actionTypes = [];
  List<String> _modules = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
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
    _refresh();
  }

  void _refresh() {
    ref.read(auditProvider.notifier).loadLogs(
      action: _actionFilter == 'all' ? null : _actionFilter,
      module: _moduleFilter == 'all' ? null : _moduleFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting audit logs...'), behavior: SnackBarBehavior.floating),
                  );
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
                _refresh();
              }),
              const SizedBox(width: 12),
              _buildDropdownFilter('Module', _moduleFilter, _modules, (v) {
                setState(() => _moduleFilter = v);
                _refresh();
              }),
              
              Text('${auditState.logs.length} events', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Activity log
          if (auditState.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (auditState.error != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${auditState.error}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
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
                              if (log.beforeValue != null && log.afterValue != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Text('Before: ', style: GoogleFonts.inter(color: Colors.red.shade300, fontSize: 10)),
                                      Text(log.beforeValue!, style: GoogleFonts.firaCode(color: Colors.red.shade300, fontSize: 10)),
                                      const SizedBox(width: 12),
                                      Text('After: ', style: GoogleFonts.inter(color: Colors.green.shade300, fontSize: 10)),
                                      Text(log.afterValue!, style: GoogleFonts.firaCode(color: Colors.green.shade300, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (log.ipAddress != null) ...[
                                    Icon(Icons.wifi, size: 12, color: Colors.white.withValues(alpha: 0.25)),
                                    const SizedBox(width: 4),
                                    Text(log.ipAddress!, style: GoogleFonts.firaCode(color: Colors.white30, fontSize: 10)),
                                    const SizedBox(width: 12),
                                  ],
                                  if (log.userAgent != null)
                                    Expanded(child: Text(log.userAgent!, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
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
