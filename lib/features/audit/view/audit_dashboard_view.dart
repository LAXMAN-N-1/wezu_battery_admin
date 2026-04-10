import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/repositories/audit_repository.dart';
import '../data/models/audit_models.dart';
import 'widgets/audit_components.dart';

class AuditDashboardView extends StatefulWidget {
  const AuditDashboardView({super.key});
  @override
  State<AuditDashboardView> createState() => _AuditDashboardViewState();
}

class _AuditDashboardViewState extends State<AuditDashboardView>
    with TickerProviderStateMixin {
  final AuditRepository _repo = AuditRepository();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _autoRefresh = true;
  bool _show24h = true; // true = 24h, false = 7d
  Timer? _refreshTimer;
  int? _touchedDonutIndex;

  final List<Map<String, String>> _criticalEvents = [];
  List<Map<String, dynamic>> _loginOrigins = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_autoRefresh && mounted) _loadData(silent: true);
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final statsRes = await _repo.getAuditStats();
      final eventsRes = await _repo.getSecurityEvents(severity: 'Critical');
      final originsRes = await _repo.getSecurityOriginMetrics();
      
      if (mounted) {
        setState(() { 
          _stats = statsRes;
          _loginOrigins = originsRes;
          
          final List<SecurityEventItem> events = eventsRes['items'] as List<SecurityEventItem>;
          if (events.isNotEmpty) {
            _criticalEvents.clear();
            for (var e in events.take(10)) {
              _criticalEvents.add({
                'time': DateFormat('HH:mm:ss').format(DateTime.parse(e.timestamp)),
                'desc': e.eventType,
                'ip': e.sourceIp ?? 'Internal',
              });
            }
          }
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _isLoading ? _buildShimmer() : _buildContent(),
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
            Text(
              'Audit & Security',
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'System-wide activity monitoring and threat management',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 15),
            ),
          ],
        ).animate().fadeIn().slideX(begin: -0.1),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Auto-refresh: 60s', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(_autoRefresh ? 'ACTIVE' : 'PAUSED', 
                        style: GoogleFonts.inter(color: _autoRefresh ? Colors.greenAccent : Colors.white24, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: _autoRefresh,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (v) => setState(() => _autoRefresh = v),
                  ),
                  if (_autoRefresh) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms).then().fadeIn(duration: 800.ms),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (i) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
          )),
        ),
        const SizedBox(height: 64),
        const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 16),
        Text('Loading Intelligence Feed...', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
      ],
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;
        return Column(
          children: [
            _buildStatCards(),
            const SizedBox(height: 32),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 65, child: _buildActivityChart()),
                  const SizedBox(width: 24),
                  Expanded(flex: 35, child: _buildCategoryDonut()),
                ],
              )
            else
              Column(
                children: [
                  _buildActivityChart(),
                  const SizedBox(height: 24),
                  _buildCategoryDonut(),
                ],
              ),
            const SizedBox(height: 32),
            _buildRecentCriticalEvents(),
            const SizedBox(height: 32),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 62, child: _buildAuthMap()),
                  const SizedBox(width: 20),
                  Expanded(flex: 38, child: _buildGlobalIntelligencePanel()),
                ],
              )
            else
              Column(
                children: [
                  _buildAuthMap(),
                  const SizedBox(height: 24),
                  _buildGlobalIntelligencePanel(),
                ],
              ),
            const SizedBox(height: 32),
            _buildThreatSummaryFooterSection(),
          ],
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 1200 ? 1.8 : 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AuditStatCard(
              title: 'Total Events Today',
              value: _formatNumber(_stats['total_today'] ?? 0),
              trend: _stats['total_trend'] ?? '0%',
              icon: Icons.analytics_outlined,
              color: Colors.blueAccent,
              onTap: () => context.push('/audit/logs'),
            ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.2),
            AuditStatCard(
              title: 'Admin Actions',
              value: _formatNumber(_stats['admin_actions'] ?? 0),
              trend: _stats['admin_trend'] ?? '0%',
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.greenAccent,
              onTap: () => context.push('/audit/logs?role=admin'),
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
            AuditStatCard(
              title: 'Failed Login Attempts',
              value: _formatNumber(_stats['failed_logins'] ?? 0),
              trend: _stats['failed_trend'] ?? '0%',
              icon: Icons.login_outlined,
              color: Colors.orangeAccent,
              onTap: () => context.push('/audit/logs?action=login&status=failed'),
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.2),
            AuditStatCard(
              title: 'Critical Events',
              value: _formatNumber(_stats['critical_events'] ?? 0),
              trend: _stats['critical_trend'] ?? '0%',
              icon: Icons.gpp_maybe_outlined,
              color: Colors.redAccent,
              onTap: () => context.push('/audit/logs?severity=Critical'),
            ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.2),
          ],
        );
      },
    );
  }

  String _formatNumber(dynamic val) {
    final n = val is int ? val : (val as num).toInt();
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }

  Widget _buildActivityChart() {
    final trends = _stats['activity_trends'] ?? {};
    final labels = List<String>.from(trends['labels'] ?? []);
    final apiRequests = List<num>.from(trends['api_requests'] ?? []);
    final failedLogins = List<num>.from(trends['failed_logins'] ?? []);

    final displayLabels = labels;
    final displayApi = apiRequests;
    final displayFailed = failedLogins;

    if (displayApi.isEmpty) {
       return const Center(child: Text("No activity data available", style: TextStyle(color: Colors.white24)));
    }

    final maxY = displayApi.reduce((a, b) => a > b ? a : b).toDouble() * 1.2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Over Time',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Row(
                children: [
                  _buildChartLegend(),
                  const SizedBox(width: 24),
                  _buildTimeToggle(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, m) => Text(
                        _formatNumber(v.toInt()),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= displayLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            displayLabels[idx],
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (event is FlTapUpEvent && touchResponse?.lineBarSpots != null) {
                      final spot = touchResponse!.lineBarSpots!.first;
                      final isApi = spot.barIndex == 0;
                      final timeLabel = displayLabels[spot.x.toInt()];
                      final period = _show24h ? 'hour' : 'day';
                      
                      String query = isApi ? '?action=api_request' : '?action=login&status=failed';
                      query += '&$period=${Uri.encodeComponent(timeLabel)}';
                      
                      context.push('/audit/logs$query');
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final label = s.barIndex == 0 ? 'API Requests' : 'Failed Logins';
                      final color = s.barIndex == 0 ? Colors.blueAccent : Colors.redAccent;
                      return LineTooltipItem(
                        '$label\n${s.y.toInt()}',
                        TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _lineBarData(displayApi.map((e) => e.toDouble()).toList(), Colors.blueAccent),
                  _lineBarData(displayFailed.map((e) => e.toDouble()).toList(), Colors.redAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _timeToggleBtn('24H', _show24h, () => setState(() => _show24h = true)),
          _timeToggleBtn('7D', !_show24h, () => setState(() => _show24h = false)),
        ],
      ),
    );
  }

  Widget _timeToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineBarData(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
          strokeColor: Colors.transparent,
        ),
      ),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      children: [
        _legendDot('API Requests', Colors.blueAccent),
        const SizedBox(width: 16),
        _legendDot('Failed Logins', Colors.redAccent),
      ],
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoryDonut() {
    final categories = _stats['event_categories'];
    final Map<String, dynamic> cats = (categories is Map)
        ? Map<String, dynamic>.from(categories)
        : {};

    final labels = cats.keys.toList();
    final values = cats.values.map((v) => (v as num).toDouble()).toList();
    final colors = [Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent, Colors.redAccent];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Categories',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 48,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.touchedSection != null) {
                      final index = response!.touchedSection!.touchedSectionIndex;
                      if (index >= 0 && index < labels.length) {
                        final label = labels[index];
                        // Map donut segments to log filter actions
                        String action = label;
                        if (label == 'Auth Events') action = 'Login';
                        if (label == 'Data Changes') action = 'Update';
                        if (label == 'Security Threats') action = 'Anomaly';
                        
                        context.push('/audit/logs?action=${Uri.encodeComponent(action)}');
                      }
                    }
                    if (response?.touchedSection != null) {
                      setState(() => _touchedDonutIndex = response!.touchedSection!.touchedSectionIndex);
                    } else {
                      setState(() => _touchedDonutIndex = null);
                    }
                  },
                ),
                sections: values.asMap().entries.map((e) {
                  final isTouched = _touchedDonutIndex == e.key;
                  return PieChartSectionData(
                    value: e.value,
                    title: '${e.value.toInt()}%',
                    color: colors[e.key % colors.length],
                    radius: isTouched ? 28 : 20,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 12 : 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...labels.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: colors[e.key % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                ),
                Text(
                  '${values[e.key].toInt()}%',
                  style: GoogleFonts.robotoMono(
                    color: colors[e.key % colors.length],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentCriticalEvents() {
    return Container(
      height: 240, // Required height from docs
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Critical Events Tracker',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              _buildLiveFeedBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _criticalEvents.length.clamp(0, 10),
              separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.03), height: 1),
              itemBuilder: (context, index) {
                final event = _criticalEvents[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 90,
                        child: Text(
                          event['time']!,
                          style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          event['desc']!,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => context.push('/audit/logs?severity=Critical'),
                        child: Text('View', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: -0.1, end: 0, duration: 400.ms, delay: (index * 40).ms).fadeIn();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms).then().fadeIn(duration: 800.ms),
          const SizedBox(width: 8),
          Text(
            'LIVE FEED',
            style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  // ─── Authentication Map — Globe Visualization ─────────────────────────────

  // ── Authentication Map Card (Left Panel) ──────────────────────────────────
  Widget _buildAuthMap() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Map',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Global distribution of access attempts',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/audit/logs'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Attempts',
                      style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: Colors.blueAccent, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Globe Visualization ──
          _buildGlobeVisualization(),

          const SizedBox(height: 16),

          // ── Legend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _globeLegendItem('Successful', Colors.greenAccent),
              const SizedBox(width: 24),
              _globeLegendItem('Failed', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _globeLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  // ── Globe with markers ────────────────────────────────────────────────────
  Widget _buildGlobeVisualization() {
    return Center(
      child: SizedBox(
        width: 320,
        height: 320,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;
            final globeRadius = constraints.maxWidth / 2 - 10;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Globe background with dot-matrix
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _GlobeMapPainter(globeRadius: globeRadius),
                ),

                // Markers for each origin
                ..._loginOrigins.map((origin) {
                  final angle = (origin['angle'] as double);
                  final dist = (origin['dist'] as double);
                  final markerSize = ((origin['attempts'] as int) / 2500 * 10).clamp(5.0, 12.0);

                  // Convert polar to cartesian within the globe circle
                  final r = dist * globeRadius;
                  final dx = centerX + r * math.cos(angle) - markerSize / 2;
                  final dy = centerY + r * math.sin(angle) - markerSize / 2;

                  final markerColor = origin['failed'] > 100 ? Colors.redAccent : Colors.greenAccent;

                  return Positioned(
                    left: dx,
                    top: dy,
                    child: _buildGlobeMarker(origin, markerColor, markerSize, origin['failed'] > 100),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }



  Widget _buildGlobeMarker(Map<String, dynamic> origin, Color color, double size, bool isThreat) {
    return Tooltip(
      message: '${origin['flag']} ${origin['country']}: ${origin['attempts']} attempts (${origin['rate']}% success)',
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring for threats
          if (isThreat)
            Container(
              width: size * 3.5,
              height: size * 3.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.06),
              ),
            ).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.5, end: 1.5, duration: 1800.ms).fadeOut(begin: 0.4, duration: 1800.ms),
          // Glow halo
          Container(
            width: size * 2.2,
            height: size * 2.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
          ),
          // Core marker
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 10, spreadRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }

  // ── Global Access Intelligence Panel (Right Panel) ────────────────────────
  Widget _buildGlobalIntelligencePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Access Intelligence',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Originating Country', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('Attempts', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('Success Rate', style: _tableHeaderStyle())),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),

          // Country rows
          ...List.generate(_loginOrigins.length, (i) {
            final origin = _loginOrigins[i];
            return _buildIntelligenceRow(origin, i);
          }),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() => GoogleFonts.inter(
    color: Colors.white24,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  Widget _buildIntelligenceRow(Map<String, dynamic> origin, int index) {
    final rate = origin['rate'] as double;
    final risk = origin['risk'] as String;
    final rateColor = rate > 90 ? Colors.greenAccent : rate > 70 ? Colors.orangeAccent : Colors.redAccent;
    final isBlocked = origin['blocked'] as bool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: risk == 'critical' ? Colors.redAccent.withValues(alpha: 0.03) : Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          // Country with flag
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(origin['flag'] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        origin['country'] as String,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (risk == 'critical' && !isBlocked)
                        GestureDetector(
                          onTap: () => _showBlockOriginDialog(origin, index),
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('THREAT', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      if (isBlocked)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.block, color: Colors.white24, size: 10),
                            const SizedBox(width: 3),
                            Text('Blocked', style: GoogleFonts.inter(color: Colors.white24, fontSize: 9)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Attempts
          Expanded(
            flex: 2,
            child: Text(
              _formatK(origin['attempts'] as int),
              style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          // Success Rate with visual bar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: rate / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(rateColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$rate%',
                  style: GoogleFonts.robotoMono(color: rateColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40)).slideX(begin: -0.03);
  }

  String _formatK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ── Block Origin Confirmation Dialog ──────────────────────────────────────
  void _showBlockOriginDialog(Map<String, dynamic> origin, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent, width: 1)),
        title: Row(
          children: [
            const Icon(Icons.gpp_bad_outlined, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text('Block ${origin['country']}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Threat Summary for ${origin['flag']} ${origin['country']}:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _dialogStat('Total Attempts', '${origin['attempts']}'),
                  _dialogStat('Failed Logins', '${origin['failed']}', color: Colors.redAccent),
                  _dialogStat('Success Rate', '${origin['rate']}%', color: Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will block all IP ranges associated with ${origin['country']}. Legitimate users from this region will be unable to access the admin portal.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.addToBlacklist({
                  'type': 'country',
                  'value': origin['code'],
                  'reason': 'Blocked regional threat from ${origin['country']}',
                });
                if (mounted) {
                  setState(() {
                    _loginOrigins[index]['blocked'] = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text('All IP ranges from ${origin['country']} blocked', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      backgroundColor: Colors.redAccent.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block origin: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            icon: const Icon(Icons.block, size: 14),
            label: Text('Block IP Range', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogStat(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          Text(value, style: GoogleFonts.robotoMono(color: color ?? Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Threat Summary Footer (standalone full-width section) ─────────────────
  Widget _buildThreatSummaryFooterSection() {
    final totalAttempts = _loginOrigins.fold<int>(0, (s, e) => s + (e['attempts'] as int));
    final totalFailed = _loginOrigins.fold<int>(0, (s, e) => s + (e['failed'] as int));
    final criticalCount = _loginOrigins.where((e) => e['risk'] == 'critical').length;
    final globalRate = totalAttempts > 0 ? ((totalAttempts - totalFailed) / totalAttempts * 100) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0F172A), const Color(0xFF1E293B).withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: isWide 
            ? Row(
                children: [
                  _footerStat('TOTAL ATTEMPTS', _formatK(totalAttempts), Colors.blueAccent),
                  _footerDivider(),
                  _footerStat('FAILED LOGINS', _formatK(totalFailed), Colors.redAccent),
                  _footerDivider(),
                  _footerStat('GLOBAL SUCCESS', '${globalRate.toStringAsFixed(1)}%', globalRate > 85 ? Colors.greenAccent : Colors.orangeAccent),
                  _footerDivider(),
                  _footerStat('THREAT ORIGINS', '$criticalCount', criticalCount > 0 ? Colors.redAccent : Colors.greenAccent),
                  _footerDivider(),
                  _footerStat('UNIQUE COUNTRIES', '${_loginOrigins.length}', Colors.purpleAccent),
                ],
              )
            : Wrap(
                runSpacing: 20,
                spacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _footerStatMobile('TOTAL ATTEMPTS', _formatK(totalAttempts), Colors.blueAccent),
                  _footerStatMobile('FAILED LOGINS', _formatK(totalFailed), Colors.redAccent),
                  _footerStatMobile('GLOBAL SUCCESS', '${globalRate.toStringAsFixed(1)}%', globalRate > 85 ? Colors.greenAccent : Colors.orangeAccent),
                  _footerStatMobile('THREAT ORIGINS', '$criticalCount', criticalCount > 0 ? Colors.redAccent : Colors.greenAccent),
                  _footerStatMobile('UNIQUE', '${_loginOrigins.length}', Colors.purpleAccent),
                ],
              ),
        );
      },
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _footerStatMobile(String label, String value, Color color) {
    return SizedBox(
       width: 100,
       child: Column(
         children: [
           Text(value, style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
           const SizedBox(height: 2),
           Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
         ],
       ),
    );
  }

  Widget _footerStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _footerDivider() {
    return Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.06));
  }
}

// ─── Circular Globe Dot-Matrix Painter ────────────────────────────────────
class _GlobeMapPainter extends CustomPainter {
  final double globeRadius;
  _GlobeMapPainter({required this.globeRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.3),
          const Color(0xFF0F172A).withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: globeRadius));
    canvas.drawCircle(Offset(cx, cy), globeRadius, glowPaint);

    // Globe border ring
    final borderPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), globeRadius, borderPaint);

    // Inner ring (equator effect)
    final innerRingPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(cx, cy), globeRadius * 0.7, innerRingPaint);
    canvas.drawCircle(Offset(cx, cy), globeRadius * 0.4, innerRingPaint);

    // Dot-matrix grid within the globe circle
    final dotPaint = Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.6);
    final landPaint = Paint()..color = const Color(0xFF475569).withValues(alpha: 0.5);

    const spacing = 7.0;
    final cols = (size.width / spacing).floor();
    final rows = (size.height / spacing).floor();

    // Simplified continent zones (relative to globe center)
    // These create a rough approximation of continental outlines
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * spacing + spacing / 2;
        final y = r * spacing + spacing / 2;
        final dx = x - cx;
        final dy = y - cy;
        final distFromCenter = _sqrt(dx * dx + dy * dy);

        // Only draw dots inside the globe
        if (distFromCenter > globeRadius - 4) continue;

        // Determine if this dot is in a "land" region
        final normX = dx / globeRadius; // -1 to 1
        final normY = dy / globeRadius; // -1 to 1
        final isLand = _isLandArea(normX, normY);

        canvas.drawCircle(
          Offset(x, y),
          isLand ? 1.4 : 0.6,
          isLand ? landPaint : dotPaint,
        );
      }
    }

    // Latitude/longitude grid lines (subtle)
    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Horizontal latitude lines
    for (double lat = -0.6; lat <= 0.6; lat += 0.3) {
      final lineY = cy + lat * globeRadius;
      final halfWidth = _sqrt(1 - lat * lat) * globeRadius;
      canvas.drawLine(
        Offset(cx - halfWidth, lineY),
        Offset(cx + halfWidth, lineY),
        gridPaint,
      );
    }

    // Vertical longitude arcs (simplified as lines)
    for (double lon = -0.6; lon <= 0.6; lon += 0.3) {
      final lineX = cx + lon * globeRadius;
      final halfHeight = _sqrt(1 - lon * lon) * globeRadius;
      canvas.drawLine(
        Offset(lineX, cy - halfHeight),
        Offset(lineX, cy + halfHeight),
        gridPaint,
      );
    }
  }

  bool _isLandArea(double x, double y) {
    // Rough continental shapes mapped to normalized -1..1 coords

    // North America
    if (x > -0.85 && x < -0.35 && y > -0.65 && y < -0.05) return true;
    // Central America
    if (x > -0.55 && x < -0.35 && y > -0.05 && y < 0.15) return true;
    // South America
    if (x > -0.55 && x < -0.2 && y > 0.1 && y < 0.7) return true;
    // Europe
    if (x > -0.1 && x < 0.2 && y > -0.7 && y < -0.25) return true;
    // Africa
    if (x > -0.1 && x < 0.15 && y > -0.2 && y < 0.55) return true;
    // Russia / North Asia
    if (x > 0.15 && x < 0.8 && y > -0.7 && y < -0.3) return true;
    // Middle East / India
    if (x > 0.15 && x < 0.45 && y > -0.3 && y < 0.05) return true;
    // East Asia / China
    if (x > 0.4 && x < 0.75 && y > -0.35 && y < 0.0) return true;
    // Southeast Asia
    if (x > 0.45 && x < 0.7 && y > 0.0 && y < 0.2) return true;
    // Australia
    if (x > 0.55 && x < 0.85 && y > 0.35 && y < 0.6) return true;

    return false;
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 15; i++) {
      x = 0.5 * (x + v / x);
    }
    return x;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
