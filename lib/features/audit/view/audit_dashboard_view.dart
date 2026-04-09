import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../data/models/audit_models.dart';
import '../data/providers/audit_dashboard_provider.dart';
import '../data/repositories/audit_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class AuditDashboardView extends ConsumerWidget {
  const AuditDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auditDashboardProvider);
    final notifier = ref.read(auditDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state, notifier, ref),
            const SizedBox(height: 24),
            if (state.isLoading && state.stats == null)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null)
              _buildError(state.error!)
            else if (state.stats != null)
              _buildDashboard(context, state.stats!, state, notifier, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuditDashboardState state, AuditDashboardNotifier notifier, WidgetRef ref) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Audit & Security Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time system activity monitoring and threat intelligence oversight',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.isAutoRefreshEnabled ? 'Live Monitoring Active' : 'Auto-refresh Paused',
                  style: GoogleFonts.inter(
                    color: state.isAutoRefreshEnabled ? const Color(0xFF10B981) : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Next update in 60s',
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Switch(
              value: state.isAutoRefreshEnabled,
              onChanged: notifier.toggleAutoRefresh,
              thumbColor: WidgetStateProperty.all(const Color(0xFF10B981)),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF10B981).withValues(alpha: 0.2);
                }
                return null;
              }),
            ),
            const SizedBox(width: 16),
             _buildExportButton(context, ref),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: IconButton(
        onPressed: () async {
          final repo = ref.read(auditRepositoryProvider);
          final url = await repo.exportAuditLogs();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report generated successfully: $url'),
                backgroundColor: const Color(0xFF10B981),
                action: SnackBarAction(label: 'Copy URL', textColor: Colors.white, onPressed: () {}),
              ),
            );
          }
        },
        icon: const Icon(Icons.download_rounded, color: Color(0xFF3B82F6)),
        tooltip: 'Export Audit Log',
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load dashboard data:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AuditDashboardStats stats, AuditDashboardState state, AuditDashboardNotifier notifier, WidgetRef ref) {
    return Column(
      children: [
        _buildStatsStrip(context, stats),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildActivityChart(context, state, notifier)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildCategoryDonut(context, stats.categoryDistribution, stats.totalEventsToday)),
          ],
        ),
        const SizedBox(height: 32),
        _buildRecentCriticalEvents(context, stats.recentCriticalEvents),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildAuthenticationMapWidget(context)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildGlobalIntelligenceTable(context, stats.topLocations)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsStrip(BuildContext context, AuditDashboardStats stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard(
          'Total Events Today',
          stats.totalEventsToday.toString(),
          Icons.analytics_rounded,
          const Color(0xFF3B82F6),
          () {
            if (context.mounted) context.go('/audit/logs');
          },
        ),
        _statCard(
          'Admin Actions',
          stats.adminActionsToday.toString(),
          Icons.admin_panel_settings_rounded,
          const Color(0xFF10B981),
          () {
            if (context.mounted) context.go('/audit/logs?action=admin');
          },
        ),
        _statCard(
          'Failed Login Attempts',
          stats.failedLoginsToday.toString(),
          Icons.login_rounded,
          const Color(0xFFF59E0B),
          () {
            if (context.mounted) context.go('/audit/logs?status=failed&action=login');
          },
        ),
        _statCard(
          'Critical Events',
          stats.criticalEventsToday.toString(),
          Icons.report_gmailerrorred_rounded,
          const Color(0xFFEF4444),
          () {
             if (context.mounted) context.go('/audit/logs?severity=critical');
          },
          isAlert: stats.criticalEventsToday > 0,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, VoidCallback onTap, {bool isAlert = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 240),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // If narrow, don't use Expanded. If in a Row, the parent will handle flex.
          // Since we are now using Wrap, we specify a minimum width.
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context, AuditDashboardState state, AuditDashboardNotifier notifier) {
    final points = state.stats?.activityPoints ?? [];
    return Container(
      height: 440,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Over Time',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text('System requests vs failed login attempts', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _timeToggleBtn('24h', state.selectedTimeRange == '24h', () => notifier.setTimeRange('24h')),
                    _timeToggleBtn('7d', state.selectedTimeRange == '7d', () => notifier.setTimeRange('7d')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.lineBarSpots != null) {
                      final spot = response!.lineBarSpots!.first;
                      final isFailed = spot.barIndex == 1;
                      // Navigate to logs pre-filtered by date/severity or action
                      if (context.mounted) {
                        if (isFailed) {
                          context.go('/audit/logs?status=failed&action=login');
                        } else {
                          context.go('/audit/logs?severity=info');
                        }
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF334155),
                    getTooltipItems: (items) => items.map((i) => LineTooltipItem(
                      '${i.barIndex == 0 ? "Requests" : "Failed"}: ${i.y.toInt()}',
                      GoogleFonts.inter(color: i.barIndex == 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444), fontWeight: FontWeight.bold),
                    )).toList(),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.03), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < points.length) {
                      return Padding(padding: const EdgeInsets.only(top: 12), child: Text(points[value.toInt()].time, style: const TextStyle(color: Colors.white38, fontSize: 10)));
                    }
                    return const SizedBox();
                  })),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF3B82F6).withValues(alpha: 0.15), const Color(0xFF3B82F6).withValues(alpha: 0)])),
                    spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.apiRequests.toDouble())).toList(),
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFEF4444).withValues(alpha: 0.15), const Color(0xFFEF4444).withValues(alpha: 0)])),
                    spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.failedLogins.toDouble())).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('API Requests', const Color(0xFF3B82F6)),
              const SizedBox(width: 32),
              _legendItem('Failed Logins', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeToggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoryDonut(BuildContext context, Map<String, double> distribution, int total) {
    return Container(
      height: 440,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Event Categories',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, size: 16, color: Colors.white38),
            ],
          ),
          const SizedBox(height: 8),
          Text('Distribution of events by category', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
          const SizedBox(height: 32),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response?.touchedSection != null) {
                          final index = response!.touchedSection!.touchedSectionIndex;
                          final categories = distribution.keys.toList();
                          if (context.mounted && index >= 0 && index < categories.length) {
                             context.go('/audit/logs?module=${categories[index]}');
                          }
                        }
                      },
                    ),
                    sections: [
                      PieChartSectionData(color: const Color(0xFF3B82F6), value: distribution['Auth Events'] ?? 35, showTitle: false, radius: 20),
                      PieChartSectionData(color: const Color(0xFF10B981), value: distribution['Data Changes'] ?? 25, title: '', radius: 20),
                      PieChartSectionData(color: const Color(0xFFF59E0B), value: distribution['System Events'] ?? 20, title: '', radius: 20),
                      PieChartSectionData(color: const Color(0xFFEF4444), value: distribution['Security Threats'] ?? 20, title: '', radius: 20),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.compact().format(total),
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text('Total', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _categoryRow('Auth Events', const Color(0xFF3B82F6), '35%', context),
          _categoryRow('Data Changes', const Color(0xFF10B981), '25%', context),
          _categoryRow('System Events', const Color(0xFFF59E0B), '20%', context),
          _categoryRow('Security Threats', const Color(0xFFEF4444), '20%', context),
        ],
      ),
    );
  }

  Widget _categoryRow(String label, Color color, String percent, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (context.mounted) context.go('/audit/logs?module=$label');
        },
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text(percent, style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCriticalEvents(BuildContext context, List<SecurityEventItem> events) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Critical Events',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 24),
              _liveFeedIndicator(),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  if (context.mounted) context.go('/audit/logs?severity=critical');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('View All Logs', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('High severity events requiring immediate attention', style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
          const SizedBox(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length.clamp(0, 4),
            separatorBuilder: (context, index) => Container(height: 1, color: Colors.white.withValues(alpha: 0.03)),
            itemBuilder: (context, index) {
              final event = events[index];
              return _criticalEventRow(context, event);
            },
          ),
        ],
      ),
    );
  }

  Widget _liveFeedIndicator() {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 800.ms).fadeOut(),
          const SizedBox(width: 8),
          Text('LIVE FEED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _criticalEventRow(BuildContext context, SecurityEventItem event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 100,
            child: Text(
              _formatTime(event.timestamp),
              style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
             child: Text('HIGH', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.redAccent)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.details, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Source: ', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
                    Flexible(child: Text(event.sourceIp ?? '127.0.0.1 (System)', style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('User Account', style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
              Text(event.eventType.split(' ').last, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(width: 40),
          AdminButton(
            label: 'View',
            width: 80,
            height: 36,
            onPressed: () {
               if (context.mounted) context.go('/audit/logs?id=${event.id}');
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(String ts) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(ts));
    } catch (_) {
      return '--:--';
    }
  }

  Widget _buildAuthenticationMapWidget(BuildContext context) {
    return Container(
      height: 480,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Map',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text('Global distribution of access attempts', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
                ],
              ),
              TextButton(
              onPressed: () {
                if (context.mounted) context.go('/audit/logs?action=login');
              },
                child: Row(
                  children: [
                    const Text('View All Attempts'),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_right_alt, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              children: [
                // Stylized World Map Background
                Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.public, size: 300, color: Colors.white),
                  ),
                ),
                // Mock points for different regions
                 _mapPoint(0.3, 0.4, Colors.greenAccent), // US
                 _mapPoint(0.35, 0.42, Colors.redAccent), // US Failed
                 _mapPoint(0.5, 0.35, Colors.greenAccent), // Europe
                 _mapPoint(0.52, 0.37, Colors.redAccent), // Europe Failed
                 _mapPoint(0.7, 0.45, Colors.greenAccent), // Asia
                 _mapPoint(0.72, 0.47, Colors.redAccent), // Asia Failed
                 _mapPoint(0.68, 0.43, Colors.redAccent), // Asia Failed 2
                 _mapPoint(0.6, 0.7, Colors.greenAccent), // Africa
                 _mapPoint(0.35, 0.75, Colors.greenAccent), // South America
                 _mapPoint(0.75, 0.75, Colors.greenAccent), // Australia
                
                // Legend Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _mapLegendItem('Successful', Colors.green),
                        const SizedBox(width: 16),
                        _mapLegendItem('Failed', Colors.red),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPoint(double top, double left, Color color) {
    return Align(
      alignment: Alignment(left * 2 - 1, top * 2 - 1),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat())
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
        .then().scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
    );
  }

  Widget _mapLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildGlobalIntelligenceTable(BuildContext context, List<LocationStat> locations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Access Intelligence',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                children: [
                  _tableHeader('Originating Country'),
                  _tableHeader('Attempts'),
                  _tableHeader('Success Rate'),
                ],
              ),
              ..._buildLocationRows(locations, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: GoogleFonts.inter(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _getFlagEmoji(String country) {
    switch (country.toLowerCase()) {
      case 'india': return '🇮🇳';
      case 'united states': return '🇺🇸';
      case 'germany': return '🇩🇪';
      case 'united kingdom': return '🇬🇧';
      case 'china': return '🇨🇳';
      case 'russia': return '🇷🇺';
      case 'australia': return '🇦🇺';
      case 'brazil': return '🇧🇷';
      case 'singapore': return '🇸🇬';
      default: return '🏳️';
    }
  }

  List<TableRow> _buildLocationRows(List<LocationStat> locations, BuildContext context) {
    return locations.map((row) {
      final successValue = double.tryParse(row.successRate.replaceAll('%', '')) ?? 0.0;
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: InkWell(
              onTap: () {
                if (context.mounted) context.go('/audit/logs?search=${row.country}');
              },
              child: Row(
                children: [
                  Text(_getFlagEmoji(row.country), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Text(row.country, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(row.attempts, style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(row.successfulAttempts, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(row.successRate, style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: successValue / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(successValue > 90 ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }
}
