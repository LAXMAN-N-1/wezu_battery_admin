import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../data/models/audit_models.dart';
import '../data/repositories/audit_repository.dart';
import 'widgets/audit_components.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class FraudRiskView extends StatefulWidget {
  const FraudRiskView({super.key});
  @override
  State<FraudRiskView> createState() => _FraudRiskViewState();
}

class _FraudRiskViewState extends SafeState<FraudRiskView>
    with TickerProviderStateMixin {
  final AuditRepository _repo = AuditRepository();
  List<FraudAlert> _alerts = [];
  bool _isLoading = true;
  FraudAlert? _selectedAlert;
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  String _statusFilter = 'All';
  int? _touchedDonut;

  final _statuses = ['All', 'Open', 'Under Investigation', 'Resolved', 'False Positive'];



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getFraudAlerts();
      final items = res['items'] as List<FraudAlert>? ?? [];
      if (mounted) setState(() { _alerts = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FraudAlert> get _filteredAlerts {
    if (_statusFilter == 'All') return _alerts;
    return _alerts.where((a) => a.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSummaryStrip(),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 60, child: _buildTrendChart()),
                        const SizedBox(width: 20),
                        Expanded(flex: 40, child: _buildCategoryDonut()),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildStatusFilterRow(),
                    const SizedBox(height: 16),
                    _buildAlertsTable(),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
        if (_selectedAlert != null) _buildInvestigationDrawer(),
      ],
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fraud & Risk Analysis',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor suspicious patterns and manage risk across the platform',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms).then().fadeIn(duration: 800.ms),
            const SizedBox(width: 8),
            Text('Live Monitoring', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  // ─── Summary Strip ────────────────────────────────────────────────────────
  Widget _buildSummaryStrip() {
    final highRisk = _alerts.where((a) => a.riskScore >= 80).length;
    final investigating = _alerts.where((a) => a.status == 'Under Investigation').length;
    final resolved = _alerts.where((a) => a.status == 'Resolved').length;

    return Row(
      children: [
        _summaryCard('High Risk', '$highRisk', 'Open critical cases', Colors.redAccent, Icons.dangerous_outlined),
        const SizedBox(width: 16),
        _summaryCard('Under Investigation', '$investigating', 'Active investigations', Colors.orangeAccent, Icons.manage_search_outlined),
        const SizedBox(width: 16),
        _summaryCard('Resolved Today', '$resolved', 'Cases closed', Colors.greenAccent, Icons.check_circle_outline),
      ],
    );
  }

  Widget _summaryCard(String title, String value, String sub, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),
    );
  }

  // ─── Trend Chart ─────────────────────────────────────────────────────────
  Widget _buildTrendChart() {
    final List<double> detected = [];
    final List<double> resolved = [];

    if (detected.isEmpty && resolved.isEmpty) {
        return Container(
          height: 220,
          alignment: Alignment.center,
          child: Text('No historical fraud data available', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
        );
    }

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
                'Fraud Attempts — Last 30 Days',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Row(
                children: [
                  _legendDot('Detected', Colors.redAccent),
                  const SizedBox(width: 16),
                  _legendDot('Resolved', Colors.greenAccent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
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
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i % 7 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Day ${i + 1}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final label = s.barIndex == 0 ? 'Detected' : 'Resolved';
                      final color = s.barIndex == 0 ? Colors.redAccent : Colors.greenAccent;
                      return LineTooltipItem(
                        '$label: ${s.y.toInt()}',
                        TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _lineBar(detected, Colors.redAccent),
                  _lineBar(resolved, Colors.greenAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.07)),
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

  // ─── Category Donut ───────────────────────────────────────────────────────
  Widget _buildCategoryDonut() {
    final Map<String, double> categories = {};
    for (var a in _alerts) {
      categories[a.alertType] = (categories[a.alertType] ?? 0) + 1;
    }
    final colors = [Colors.blueAccent, Colors.redAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.greenAccent];
    final labels = categories.keys.toList();
    final values = categories.values.toList();

    if (labels.isEmpty) {
        return Container(
          height: 180,
          alignment: Alignment.center,
          child: Text('No fraud incidents detected', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
        );
    }

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
          Text('Fraud Types', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedDonut = response?.touchedSection?.touchedSectionIndex;
                    });
                  },
                ),
                sections: values.asMap().entries.map((e) {
                  final touched = _touchedDonut == e.key;
                  return PieChartSectionData(
                    value: e.value,
                    color: colors[e.key % colors.length],
                    radius: touched ? 26 : 18,
                    title: touched ? '${e.value.toInt()}%' : '',
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...labels.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: colors[e.key % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels[e.key],
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                ),
                Text(
                  '${values[e.key].toInt()}%',
                  style: GoogleFonts.robotoMono(
                    color: colors[e.key % colors.length],
                    fontSize: 11,
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

  // ─── Status Filter Row ────────────────────────────────────────────────────
  Widget _buildStatusFilterRow() {
    return Row(
      children: [
        Text(
          'Fraud Alerts',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final active = _statusFilter == s;
                Color chipColor = Colors.blueAccent;
                if (s == 'Open') chipColor = Colors.redAccent;
                if (s == 'Under Investigation') chipColor = Colors.orangeAccent;
                if (s == 'Resolved') chipColor = Colors.greenAccent;
                if (s == 'False Positive') chipColor = Colors.grey;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: active,
                    onSelected: (_) => setState(() => _statusFilter = s),
                    selectedColor: chipColor.withValues(alpha: 0.2),
                    checkmarkColor: chipColor,
                    labelStyle: GoogleFonts.inter(
                      color: active ? chipColor : Colors.white54,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    side: BorderSide(color: active ? chipColor.withValues(alpha: 0.4) : Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Text(
          '${_filteredAlerts.length} records',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Alerts Table ─────────────────────────────────────────────────────────
  Widget _buildAlertsTable() {
    final alerts = _filteredAlerts;

    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text('No fraud alerts found', style: GoogleFonts.inter(color: Colors.white38, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                _tableHeader('ALERT ID', flex: 2),
                _tableHeader('USER', flex: 3),
                _tableHeader('TYPE', flex: 3),
                _tableHeader('RISK', flex: 2),
                _tableHeader('DETECTED', flex: 3),
                _tableHeader('STATUS', flex: 2),
                _tableHeader('ACTION', flex: 3),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          ...alerts.asMap().entries.map((entry) {
            final i = entry.key;
            final alert = entry.value;
            return _buildAlertRow(alert, i);
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildAlertRow(FraudAlert alert, int index) {
    Color statusColor = Colors.white54;
    if (alert.status == 'Open') statusColor = Colors.redAccent;
    if (alert.status == 'Under Investigation') statusColor = Colors.orangeAccent;
    if (alert.status == 'Resolved') statusColor = Colors.greenAccent;
    if (alert.status == 'False Positive') statusColor = Colors.grey;

    Color typeColor = Colors.blueAccent;
    if (alert.alertType.contains('Login') || alert.alertType.contains('Forec')) typeColor = Colors.redAccent;
    if (alert.alertType.contains('Travel')) typeColor = Colors.purpleAccent;
    if (alert.alertType.contains('Txn')) typeColor = Colors.orangeAccent;
    if (alert.alertType.contains('Device')) typeColor = Colors.tealAccent;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAlert = alert;
          _tabController.index = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
          color: _selectedAlert?.id == alert.id
              ? Colors.blueAccent.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                alert.id,
                style: GoogleFonts.robotoMono(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    child: Text(
                      alert.userName.isNotEmpty ? alert.userName[0] : '?',
                      style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.userName,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          alert.userEmail,
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: typeColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  alert.alertType,
                  style: GoogleFonts.inter(color: typeColor, fontSize: 10, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: RiskScoreGauge(score: alert.riskScore, size: 40),
            ),
            Expanded(
              flex: 3,
              child: Text(
                DateFormat('MMM d, HH:mm').format(DateTime.parse(alert.detectedAt)),
                style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 11),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  alert.status,
                  style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _tableBtn(
                    'Investigate',
                    Colors.blueAccent,
                    () => setState(() { _selectedAlert = alert; _tabController.index = 0; }),
                  ),
                  const SizedBox(width: 6),
                  _tableBtn(
                    'Block',
                    Colors.redAccent,
                    () => _showConfirmDialog('Block Account', 'This will immediately block ${alert.userName}\'s account and revoke all active sessions.', Colors.redAccent, alert: alert, actionType: 'block'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 30)),
    );
  }

  Widget _tableBtn(String label, Color color, VoidCallback onTap) {
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ─── Investigation Drawer ─────────────────────────────────────────────────
  Widget _buildInvestigationDrawer() {
    final alert = _selectedAlert!;
    return Positioned(
      right: 0, top: 0, bottom: 0,
      child: GestureDetector(
        onTap: () {}, // prevent tap-through
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 50, offset: const Offset(-8, 0))],
            border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(alert),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _buildUserBanner(alert),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildActionBar(alert),
                    ),
                    const SizedBox(height: 20),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Timeline'),
                        Tab(text: 'Transactions'),
                        Tab(text: 'Notes'),
                      ],
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.white38,
                      indicatorColor: Colors.blueAccent,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.white.withValues(alpha: 0.06),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTimelineTab(),
                          _buildTransactionsTab(alert),
                          _buildNotesTab(alert),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerFooter(alert),
            ],
          ),
        ).animate().slideX(begin: 1, end: 0, curve: Curves.easeOutCubic, duration: 280.ms),
      ),
    );
  }

  Widget _buildDrawerHeader(FraudAlert alert) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.manage_search, color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investigation: ${alert.id}',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Opened ${DateFormat('MMM d, HH:mm').format(DateTime.parse(alert.detectedAt))}',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedAlert = null),
            icon: const Icon(Icons.close, color: Colors.white38),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildUserBanner(FraudAlert alert) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          child: Text(
            alert.userName.isNotEmpty ? alert.userName[0] : '?',
            style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.userName,
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(alert.userEmail, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${alert.notes.length + 2} previous alerts',
                      style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        RiskScoreGauge(score: alert.riskScore, size: 58),
      ],
    );
  }

  Widget _buildActionBar(FraudAlert alert) {
    return Row(
      children: [
        _actionBtn(
          'Block Account',
          Colors.redAccent,
          Icons.block_outlined,
          () => _showConfirmDialog('Block Account', 'Block ${alert.userName}\'s account immediately?', Colors.redAccent),
        ),
        const SizedBox(width: 8),
        _actionBtn(
          'Require 2FA',
          Colors.orangeAccent,
          Icons.security_outlined,
          () => _showConfirmDialog('Require 2FA', 'Force ${alert.userName} to enroll in 2FA on next login?', Colors.orangeAccent),
        ),
        const SizedBox(width: 8),
        _actionBtn(
          'Whitelist',
          Colors.greenAccent,
          Icons.verified_user_outlined,
          () => _showConfirmDialog('Whitelist User', '${alert.userName} will be removed from the risk watchlist.', Colors.greenAccent),
        ),
        const SizedBox(width: 8),
        _actionBtn(
          'False +',
          Colors.grey,
          Icons.thumb_down_outlined,
          () => _showConfirmDialog('Mark as False Positive', 'Mark this alert as a false positive?', Colors.grey),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    final events = [
      {'icon': Icons.login, 'color': Colors.redAccent, 'title': 'Login from Russia (new location)', 'detail': 'IP: 198.51.100.12 • Chrome 124 • Windows'},
      {'icon': Icons.payment, 'color': Colors.orangeAccent, 'title': 'Unusual transaction: ₹48,000', 'detail': 'Merchant: Unknown • Card: **** 4291'},
      {'icon': Icons.devices, 'color': Colors.purpleAccent, 'title': 'Login from 3 different devices in 1 hour', 'detail': 'iPhone 15, Pixel 8, MacBook Pro'},
      {'icon': Icons.person_outline, 'color': Colors.blueAccent, 'title': 'Profile information updated', 'detail': 'Changes: phone, address'},
      {'icon': Icons.vpn_key, 'color': Colors.greenAccent, 'title': 'Password changed successfully', 'detail': 'IP: 192.168.1.45 • Bengaluru, India'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final ev = events[i];
        final color = ev['color'] as Color;
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Icon(ev['icon'] as IconData, color: color, size: 14),
                  ),
                  if (i < events.length - 1)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(DateTime.now().subtract(Duration(hours: i * 2))),
                        style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ev['title'] as String,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ev['detail'] as String,
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(FraudAlert alert) {
    final txns = [
      {'id': 'TXN-8821', 'amount': '₹48,000', 'merchant': 'Unknown Merchant', 'status': 'Flagged', 'card': '**** 4291'},
      {'id': 'TXN-8810', 'amount': '₹2,400', 'merchant': 'Amazon.in', 'status': 'Success', 'card': '**** 4291'},
      {'id': 'TXN-8792', 'amount': '₹12,500', 'merchant': 'Crypto Exchange', 'status': 'Pending', 'card': '**** 4291'},
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        Text(
          'Payment Logs',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white60),
        ),
        const SizedBox(height: 12),
        ...txns.map((t) {
          final status = t['status']!;
          Color sc = Colors.greenAccent;
          if (status == 'Flagged') sc = Colors.redAccent;
          if (status == 'Pending') sc = Colors.orangeAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_outlined, color: sc, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['merchant']!, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${t['id']} • Card ${t['card']}', style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t['amount']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status, style: GoogleFonts.inter(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesTab(FraudAlert alert) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add investigation notes... (markdown supported)',
                  hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_noteController.text.trim().isEmpty) return;
                    setState(() => _isLoading = true);
                    try {
                      await _repo.saveInvestigationNote(alert.id, _noteController.text.trim());
                      _noteController.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note saved successfully'), backgroundColor: Colors.blueAccent),
                        );
                        _loadData(); // Refresh to show new note
                      }
                    } catch (e) {
                      if (mounted) {
                         setState(() => _isLoading = false);
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save note: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save_outlined, size: 14),
                  label: Text('Save Note', style: GoogleFonts.inter(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            itemCount: alert.notes.length,
            itemBuilder: (context, i) {
              final note = alert.notes[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(note.author, style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          DateFormat('MMM d, HH:mm').format(DateTime.parse(note.timestamp)),
                          style: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(note.content, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerFooter(FraudAlert alert) {
    String currentStatus = alert.status;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: StatefulBuilder(builder: (ctx, setLocal) {
              return DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: DropdownButton<String>(
                    value: currentStatus,
                    dropdownColor: const Color(0xFF1E293B),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    isExpanded: true,
                    items: ['Open', 'Under Investigation', 'Resolved', 'False Positive']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => currentStatus = v);
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await _repo.updateFraudAlertStatus(alert.id, currentStatus);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully'), backgroundColor: Colors.blueAccent));
                   _loadData();
                }
              } catch (e) {
                if (mounted) {
                   setState(() => _isLoading = false);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _showConfirmDialog(
              'Escalate to Super Admin',
              'An email notification will be sent to all Super Admins about this case.',
              Colors.purpleAccent,
              alert: alert,
              actionType: 'escalate',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purpleAccent,
              side: const BorderSide(color: Colors.purpleAccent),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Escalate', style: GoogleFonts.inter(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String title, String message, Color color, {FraudAlert? alert, String? actionType}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 22),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                if (alert != null) {
                  if (actionType == 'block') {
                    await _repo.blockUser(alert.userId, 'Blocked via Fraud Analysis console');
                  } else if (actionType == 'blacklist') {
                    await _repo.addToBlacklist({
                      'type': 'user',
                      'value': alert.userId.toString(),
                      'reason': 'Blacklisted via Fraud Analysis console',
                    });
                  } else if (actionType == 'escalate') {
                    await _repo.escalateFraudAlert(alert.id);
                  }
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title executed successfully', style: GoogleFonts.inter()),
                      backgroundColor: Colors.greenAccent.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadData(); // Refresh list to reflect changes
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to execute $title: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
