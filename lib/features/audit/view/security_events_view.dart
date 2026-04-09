import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/audit_models.dart';
import '../data/providers/security_events_provider.dart';
import '../data/providers/audit_dashboard_provider.dart';
import '../data/repositories/audit_repository.dart';

class SecurityEventsView extends ConsumerStatefulWidget {
  const SecurityEventsView({super.key});

  @override
  ConsumerState<SecurityEventsView> createState() => _SecurityEventsViewState();
}

class _SecurityEventsViewState extends ConsumerState<SecurityEventsView> {
  final ScrollController _terminalController = ScrollController();
  bool _autoScroll = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060F1A),
      body: Column(
        children: [
          _buildStatsStrip(ref, state),
          Expanded(
            child: Column(
              children: [
                _buildTerminalToolbar(state),
                Expanded(
                  child: _buildConsole(state),
                ),
              ],
            ),
          ),
          _buildTerminalStatusBar(state),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(WidgetRef ref, SecurityEventsState currentBatch) {
    final dashboardState = ref.watch(auditDashboardProvider);
    final stats = dashboardState.stats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _statCard(
            'Total Alerts',
            '${stats?.totalEventsToday ?? 0}',
            Icons.notification_important_outlined,
            const Color(0xFF3B82F6),
            () => ref.read(securityEventsProvider.notifier).setFilterSeverity(null),
            currentBatch.filterSeverity == null,
          ),
          _statCard(
            'Low Risk',
            '${stats?.infoEventsToday ?? 0}',
            Icons.shield_outlined,
            const Color(0xFF10B981),
            () => ref.read(securityEventsProvider.notifier).setFilterSeverity('low'),
            currentBatch.filterSeverity == 'low',
          ),
          _statCard(
            'Medium Risk',
            '${stats?.warningEventsToday ?? 0}',
            Icons.gpp_maybe_outlined,
            const Color(0xFFF59E0B),
            () => ref.read(securityEventsProvider.notifier).setFilterSeverity('medium'),
            currentBatch.filterSeverity == 'medium',
          ),
          _statCard(
            'Critical Threats',
            '${stats?.criticalEventsToday ?? 0}',
            Icons.report_problem_outlined,
            const Color(0xFFEF4444),
            () => ref.read(securityEventsProvider.notifier).setFilterSeverity('high'),
            currentBatch.filterSeverity == 'high' || currentBatch.filterSeverity == 'critical',
          ),
        ],
      ),
    );
  }


  Widget _statCard(String title, String value, IconData icon, Color color, VoidCallback onTap, bool isActive) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.1),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalToolbar(SecurityEventsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.terminal_rounded, color: Colors.greenAccent, size: 18),
              Text('SECURITY_WAF_CONSOLE', style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              _buildTerminalSearch(),
              _toolbarAction(Icons.download, 'Export .log', () => _exportLogs(ref)),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterTabs(state),
        ],
      ),
    );
  }

  Future<void> _exportLogs(WidgetRef ref) async {
    final repo = ref.read(auditRepositoryProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text('Preparing security logs...'),
          ],
        ),
      ),
    );

    try {
      final url = await repo.exportSecurityEvents(format: 'log');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showExportSuccess(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showExportSuccess(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Text('Export Ready', style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The security console logs have been processed and are ready for download.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: Text(url, style: GoogleFonts.firaCode(fontSize: 11, color: Colors.blueAccent)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
               // In real app, open URL
               if (Navigator.canPop(context)) {
                 Navigator.pop(context);
               }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(SecurityEventsState state) {
    final categories = ['All', 'Rate Limit', 'Injection', 'Auth Failures', 'Token Expired', 'WAF Block', 'SSL'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = (cat == 'All' && state.filterSeverity == null) || 
                            (cat.toLowerCase().contains(state.filterSeverity ?? '~~~'));
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                final filter = cat == 'All' ? null : cat.toLowerCase();
                ref.read(securityEventsProvider.notifier).setFilterSeverity(filter);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blueAccent : Colors.white54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTerminalSearch() {
    return Container(
      width: 200,
      height: 32,
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white10)),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.firaCode(fontSize: 11, color: Colors.greenAccent),
        decoration: InputDecoration(hintText: 'grep...', hintStyle: GoogleFonts.firaCode(fontSize: 11, color: Colors.white24), prefixIcon: const Icon(Icons.search, size: 14, color: Colors.white24), border: InputBorder.none, contentPadding: const EdgeInsets.only(bottom: 12)),
      ),
    );
  }

  Widget _toolbarAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white10)),
        child: Row(children: [Icon(icon, size: 14, color: Colors.white54), const SizedBox(width: 6), Text(label, style: GoogleFonts.firaCode(fontSize: 11, color: Colors.white54))]),
      ),
    );
  }

  Widget _buildConsole(SecurityEventsState state) {
    if (state.isLoading && state.events.isEmpty) {
      return _buildTerminalShimmer();
    }

    final filteredEvents = state.events.where((e) => e.eventType.toLowerCase().contains(_searchQuery.toLowerCase()) || e.details.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (filteredEvents.isEmpty) {
      return _buildTerminalEmpty();
    }

    if (_autoScroll && _terminalController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _terminalController.animateTo(_terminalController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });
    }

    return ListView.builder(
      controller: _terminalController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) => _buildTerminalLine(filteredEvents[index]),
    );
  }

  Widget _buildTerminalShimmer() {
    return ListView.builder(
      itemCount: 20,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Container(width: 40, height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2)))),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.greenAccent.withValues(alpha: 0.05)),
    );
  }

  Widget _buildTerminalEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.privacy_tip_outlined, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          Text('NO_SECURITY_THREATS_DETECTED', style: GoogleFonts.firaCode(fontSize: 14, color: Colors.greenAccent.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Text('System integrity within normal parameters.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildTerminalLine(SecurityEventItem event) {
    final severityColor = event.severity == 'critical' || event.severity == 'high' ? Colors.redAccent : event.severity == 'medium' ? Colors.orangeAccent : Colors.blueAccent;

    return InkWell(
      onTap: () => _showEventDetails(event),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('[${DateFormat('HH:mm:ss').format(DateTime.parse(event.timestamp))}]', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white24)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(event.severity.toUpperCase(), style: GoogleFonts.firaCode(fontSize: 10, fontWeight: FontWeight.bold, color: severityColor)),
            ),
            const SizedBox(width: 12),
            Text('src:', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white24)),
            Flexible(child: Text(event.sourceIp ?? '127.0.0.1', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.greenAccent.withValues(alpha: 0.7)), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Text('event:', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white24)),
            Flexible(child: Text(event.eventType, style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Expanded(child: Text('>> ${event.details}', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.01, end: 0),
    );
  }

  void _showEventDetails(SecurityEventItem event) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EventDetails',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => _buildDetailDrawer(event),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0.35, 0)).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)), child: child);
      },
    );
  }

  Widget _buildDetailDrawer(SecurityEventItem event) {
    return Material(
      color: const Color(0xFF0F172A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        height: double.infinity,
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.white10))),
        child: Column(
          children: [
            _buildDrawerHeader(event),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThreatIdentity(event),
                    const Divider(height: 64, color: Colors.white10),
                    _buildGeoSection(event),
                    const Divider(height: 64, color: Colors.white10),
                    _buildPayloadSection(event),
                    const SizedBox(height: 48),
                    _buildResolutionActions(event),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(SecurityEventItem event) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10)), color: Color(0xFF1E293B)),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Security Threat Intel', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('REF_ID: SEC-${event.id.toString().padLeft(5, '0')}', style: GoogleFonts.firaCode(fontSize: 11, color: Colors.white54)),
          ]),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatIdentity(SecurityEventItem event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CORE INTELLIGENCE', style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1)),
        const SizedBox(height: 24),
        _intelRow('Event Type', event.eventType, Icons.bug_report),
        _intelRow('Severity', event.severity.toUpperCase(), Icons.priority_high),
        _intelRow('Timestamp', event.timestamp, Icons.schedule),
        _intelRow('Status', event.isResolved ? 'RESOLVED' : 'ACTIVE THREAT', Icons.check_circle_outline),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
          child: Text(event.details, style: GoogleFonts.firaCode(fontSize: 13, color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildGeoSection(SecurityEventItem event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SOURCE TRACING', style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1)),
        const SizedBox(height: 24),
        _intelRow('IP Address', event.sourceIp ?? '127.0.0.1', Icons.language),
        _intelRow('Origin', '${event.country ?? 'LocalNetwork'} ${event.countryFlag ?? '🏠'}', Icons.place),
        _intelRow('Coordinates', 'LAT: ${event.latitude ?? 'N/A'}, LNG: ${event.longitude ?? 'N/A'}', Icons.explore),
      ],
    );
  }

  Widget _buildPayloadSection(SecurityEventItem event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RAW PAYLOAD DATA', style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
          child: Text(
            event.payload ?? '{"source": "waf_logs", "action": "blocked", "reason": "sql_injection_attempt", "fingerprint": "eb62...91a"}',
            style: GoogleFonts.firaCode(fontSize: 11, color: Colors.greenAccent.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionActions(SecurityEventItem event) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: event.isResolved ? null : () => ref.read(securityEventsProvider.notifier).resolveEvent(event.id),
            icon: const Icon(Icons.verified_user),
            label: Text(event.isResolved ? 'Already Resolved' : 'Mark as Resolved'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1), foregroundColor: Colors.green, side: BorderSide(color: Colors.green.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block),
            label: const Text('Block Source IP'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
    );
  }

  Widget _intelRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white24),
          const SizedBox(width: 12),
          Text('$label:', style: GoogleFonts.firaCode(fontSize: 11, color: Colors.white38)),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.firaCode(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTerminalStatusBar(SecurityEventsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(color: Color(0xFF111827), border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          _statusItem('EVENTS: ${state.events.length}', Colors.white38),
          const SizedBox(width: 24),
          _statusItem('WAF: ACTIVE', Colors.greenAccent),
          const SizedBox(width: 24),
          _statusItem('THREAT_LEVEL: ELEVATED', Colors.orangeAccent),
          const Spacer(),
          Row(
            children: [
              Text('AUTO_SCROLL', style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white38)),
              const SizedBox(width: 8),
              SizedBox(height: 16, width: 32, child: Switch(
                value: _autoScroll,
                onChanged: (v) => setState(() => _autoScroll = v),
                thumbColor: WidgetStateProperty.all(Colors.greenAccent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, Color color) {
    return Text(label, style: GoogleFonts.firaCode(fontSize: 10, fontWeight: FontWeight.bold, color: color));
  }
}
