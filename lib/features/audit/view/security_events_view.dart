import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../data/models/audit_models.dart';
// security_events_provider and audit_dashboard_provider not directly used — state is managed locally
import '../data/repositories/audit_repository.dart';

class SecurityEventsView extends ConsumerStatefulWidget {
  const SecurityEventsView({super.key});

  @override
  ConsumerState<SecurityEventsView> createState() => _SecurityEventsViewState();
}

class _SecurityEventsViewState extends ConsumerState<SecurityEventsView> {
  final AuditRepository _repo = AuditRepository();
  final ScrollController _terminalScrollController = ScrollController();
  
  List<SecurityEventItem> _events = [];
  Map<String, dynamic> _stats = {};
  final List<String> _terminalLogs = [];
  bool _isLoading = true;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getSecurityEvents();
      final stats = await _repo.getAuditStats();
      if (mounted) {
        setState(() {
          _events = res['items'] as List<SecurityEventItem>;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildTerminalContainer()),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: _buildActiveIncidents()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security Event Console', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Real-time threat monitoring, live log streaming, and incident prioritization', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _statusBadge('FIREWALL: ACTIVE', Colors.blueAccent),
            _statusBadge('THREAT LEVEL: LOW', Colors.greenAccent),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _miniStatCard('Total Events', '${_stats['total_today'] ?? 0}', Icons.lan_outlined, Colors.blueAccent),
        const SizedBox(width: 16),
        _miniStatCard('Blocked Requests', '${_stats['failed_logins'] ?? 0}', Icons.block_flipped, Colors.redAccent),
        const SizedBox(width: 16),
        _miniStatCard('High Risk Alerts', '${_stats['critical_events'] ?? 0}', Icons.gpp_maybe_rounded, Colors.orangeAccent),
        const SizedBox(width: 16),
        _miniStatCard('System Uptime', _stats['uptime']?.toString() ?? '99.9%', Icons.check_circle_outline, Colors.greenAccent),
      ],
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalContainer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30)],
      ),
      child: Column(
        children: [
          _buildTerminalHeader(),
          Expanded(
            child: ListView.builder(
              controller: _terminalScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _terminalLogs.length,
              itemBuilder: (context, index) {
                final log = _terminalLogs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _formatLogLine(log),
                );
              },
            ),
          ),
          _buildTerminalFooter(),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05);
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _circle(Colors.redAccent),
              const SizedBox(width: 6),
              _circle(Colors.orangeAccent),
              const SizedBox(width: 6),
              _circle(Colors.greenAccent),
              const SizedBox(width: 16),
              Flexible(
                child: Text('security@wezu: ~/logs/live_stream.log', style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _terminalLogs.clear()),
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.white38),
              ),
              const SizedBox(width: 8),
              _activeIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _activeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)).animate().fadeIn(duration: 1.seconds),
          const SizedBox(width: 6),
          Text('REC', style: GoogleFonts.robotoMono(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _formatLogLine(String log) {
    Color textColor = Colors.white70;
    if (log.contains('[CRIT]')) textColor = Colors.redAccent;
    if (log.contains('[WARN]')) textColor = Colors.orangeAccent;
    if (log.contains('[DEBG]')) textColor = Colors.blueAccent.withValues(alpha: 0.6);

    return SelectableText(
      log,
      style: GoogleFonts.sourceCodePro(color: textColor, fontSize: 13, height: 1.4),
    );
  }

  Widget _buildTerminalFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${_terminalLogs.length} lines streamed', style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 11)),
          Row(
            children: [
              Text('AUTO-SCROLL', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: _autoScroll,
                  onChanged: (v) => setState(() => _autoScroll = v),
                  activeThumbColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIncidents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ACTIVE INCIDENTS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text('${_events.where((e) => !e.isResolved).length} PENDING', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
                    itemBuilder: (context, index) {
                      final e = _events[index];
                      final color = e.severity == 'Critical' ? Colors.redAccent : e.severity == 'Warning' ? Colors.orangeAccent : Colors.blueAccent;
                      return ListTile(
                        onTap: () => _showEventSheet(e),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.security, color: color, size: 20),
                        ),
                        title: Text(e.eventType, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        subtitle: Row(
                          children: [
                            Text(DateFormat('HH:mm').format(DateTime.parse(e.timestamp)), style: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 11)),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Colors.white12)),
                            const SizedBox(width: 8),
                            Text(e.sourceIp ?? 'Local', style: GoogleFonts.robotoMono(color: Colors.blueAccent.withValues(alpha: 0.5), fontSize: 11)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
                      );
                    },
                  ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  void _showEventSheet(SecurityEventItem event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _buildDetailSheet(event),
    );
  }

  Widget _buildDetailSheet(SecurityEventItem event) {
    final color = event.severity == 'Critical' ? Colors.redAccent : event.severity == 'Warning' ? Colors.orangeAccent : Colors.blueAccent;
    
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.security, color: color, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.eventType, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(DateFormat('MMMM d, yyyy — HH:mm:ss.SSS').format(DateTime.parse(event.timestamp)), style: GoogleFonts.inter(color: Colors.white38)),
                    ],
                  ),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54, size: 28)),
            ],
          ),
          const SizedBox(height: 40),
          _detailSection('INCIDENT INTELLIGENCE', [
            _detailDataRow('Event ID', 'AUD-${event.id.toString()}'),
            _detailDataRow('Origin Source', event.sourceIp ?? 'Internal System'),
            _detailDataRow('Severity Level', event.severity.toUpperCase(), color: color),
            _detailDataRow('System Status', event.isResolved ? 'RESOLVED' : 'ACTIVE THREAT', color: event.isResolved ? Colors.greenAccent : Colors.redAccent),
          ]),
          const SizedBox(height: 32),
          _detailSection('EVENT DESCRIPTION', [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
              child: Text(event.details, style: GoogleFonts.inter(color: Colors.white70, height: 1.6, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 32),
          if (event.payload != null)
            _detailSection('RAW PAYLOAD DATA (LOG)', [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF030712),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    event.payload!,
                    style: GoogleFonts.sourceCodePro(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ),
              ),
            ]),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _repo.resolveSecurityEvent(event.id);
                    Navigator.pop(context);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3))),
                  ),
                  child: Text('RESOLVE INCIDENT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3))),
                  ),
                  child: Text('ESCALATE TO SOC', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _detailDataRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white30, fontSize: 14)),
          Text(value, style: GoogleFonts.robotoMono(color: color ?? Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
