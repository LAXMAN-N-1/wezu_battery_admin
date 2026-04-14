import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/audit_models.dart';
import '../data/providers/fraud_provider.dart';
import '../../../core/widgets/admin_ui_components.dart';

class FraudDashboardView extends ConsumerStatefulWidget {
  const FraudDashboardView({super.key});

  @override
  ConsumerState<FraudDashboardView> createState() => _FraudDashboardViewState();
}

class _FraudDashboardViewState extends ConsumerState<FraudDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fraudProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummaryStrip(state),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildTrendChart()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildCategoryDonut()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTrendChart(),
                      const SizedBox(height: 24),
                      _buildCategoryDonut(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            _buildAlertsTable(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Fraud & Risk Analysis',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor suspicious patterns and manage risk across the platform',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
        ]),
        const Spacer(),
        _buildActionMenu(),
      ],
    );
  }

  Widget _buildActionMenu() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
          label: Text('Re-evaluate Risks', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip(FraudState state) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _summaryCard(
          'High Risk',
          '${state.highRiskCount}',
          const Color(0xFFEF4444),
          Icons.cancel_outlined,
          'Open critical cases',
        ),
        _summaryCard(
          'Under Investigation',
          '${state.investigatingCount}',
          const Color(0xFFF59E0B),
          Icons.manage_search_rounded,
          'Active investigations',
        ),
        _summaryCard(
          'Resolved Today',
          '${state.resolvedCount}',
          const Color(0xFF10B981),
          Icons.check_circle_outline,
          '+2 from yesterday',
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon, String subtitle) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
                'Fraud Attempts — Last 30 Days',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              _chartLabel('Detected', const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _chartLabel('Resolved', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.03),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('Day 1', style: TextStyle(color: Colors.white24, fontSize: 10));
                        if (value == 3) return const Text('Day 8', style: TextStyle(color: Colors.white24, fontSize: 10));
                        if (value == 6) return const Text('Day 15', style: TextStyle(color: Colors.white24, fontSize: 10));
                        if (value == 9) return const Text('Day 22', style: TextStyle(color: Colors.white24, fontSize: 10));
                        if (value == 11) return const Text('Day 29', style: TextStyle(color: Colors.white24, fontSize: 10));
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 10), const FlSpot(1, 15), const FlSpot(2, 12), const FlSpot(3, 22),
                      const FlSpot(4, 18), const FlSpot(5, 28), const FlSpot(6, 25), const FlSpot(7, 38),
                      const FlSpot(8, 32), const FlSpot(9, 42), const FlSpot(10, 35), const FlSpot(11, 45),
                    ],
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEF4444).withValues(alpha: 0.1),
                          const Color(0xFFEF4444).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 5), const FlSpot(1, 8), const FlSpot(2, 6), const FlSpot(3, 15),
                      const FlSpot(4, 10), const FlSpot(5, 20), const FlSpot(6, 15), const FlSpot(7, 28),
                      const FlSpot(8, 22), const FlSpot(9, 32), const FlSpot(10, 25), const FlSpot(11, 35),
                    ],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.1),
                          const Color(0xFF10B981).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLabel(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoryDonut() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fraud Types',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(color: const Color(0xFF3B82F6), value: 35, showTitle: false, radius: 20),
                  PieChartSectionData(color: const Color(0xFFEF4444), value: 25, showTitle: false, radius: 20),
                  PieChartSectionData(color: const Color(0xFFF59E0B), value: 20, showTitle: false, radius: 20),
                  PieChartSectionData(color: const Color(0xFF8B5CF6), value: 15, showTitle: false, radius: 20),
                  PieChartSectionData(color: const Color(0xFF10B981), value: 5, showTitle: false, radius: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _donutLegend('Transaction Fraud', const Color(0xFF3B82F6), '35%'),
          _donutLegend('Login Abuse', const Color(0xFFEF4444), '25%'),
          _donutLegend('Account Takeover', const Color(0xFFF59E0B), '20%'),
          _donutLegend('Multiple Devices', const Color(0xFF8B5CF6), '15%'),
          _donutLegend('Impossible Travel', const Color(0xFF10B981), '5%'),
        ],
      ),
    );
  }

  Widget _donutLegend(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
          const Spacer(),
          Text(percent, style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAlertsTable(FraudState state) {
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Fraud Alerts',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 32),
                _buildFilterChip('All', isActive: state.filterStatus == null, onTap: () => ref.read(fraudProvider.notifier).setFilterStatus(null)),
                const SizedBox(width: 12),
                _buildFilterChip('Open', isActive: state.filterStatus == 'Open', onTap: () => ref.read(fraudProvider.notifier).setFilterStatus('Open')),
                const SizedBox(width: 12),
                _buildFilterChip('Under Investigation', isActive: state.filterStatus == 'Investigation', onTap: () => ref.read(fraudProvider.notifier).setFilterStatus('Investigation')),
                const SizedBox(width: 12),
                _buildFilterChip('Resolved', isActive: state.filterStatus == 'Resolved', onTap: () => ref.read(fraudProvider.notifier).setFilterStatus('Resolved')),
                const SizedBox(width: 12),
                _buildFilterChip('False Positive', isActive: state.filterStatus == 'False Positive', onTap: () => ref.read(fraudProvider.notifier).setFilterStatus('False Positive')),
                const SizedBox(width: 32),
                Text('${state.alerts.length} records', style: GoogleFonts.inter(fontSize: 13, color: Colors.white24)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
               width: 1188, // 1140 (columns) + 48 (horizontal padding)
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   _buildTableHeader(),
                   const SizedBox(height: 8),
                   if (state.isLoading)
                     const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                   else if (state.alerts.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No active threats detected.', style: TextStyle(color: Colors.white38))))
                   else
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: state.alerts.length,
                       itemBuilder: (context, index) => _buildAlertRow(state.alerts[index]),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _tblHdr('ALERT ID', 140),
          _tblHdr('USER', 220),
          _tblHdr('TYPE', 220),
          _tblHdr('RISK', 120),
          _tblHdr('DETECTED', 180),
          _tblHdr('STATUS', 140),
          _tblHdr('ACTION', 120),
        ],
      ),
    );
  }

  Widget _tblHdr(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white24,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: isActive ? Colors.blueAccent : Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (isActive) ...[
              const Icon(Icons.check, size: 14, color: Colors.blueAccent),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blueAccent : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertRow(FraudAlert alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _showInvestigationDrawer(alert),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  alert.id.toUpperCase(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      child: Text(
                        alert.userName[0],
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.userName,
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            alert.userEmail,
                            style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                child: _buildTypeBadge(alert.alertType),
              ),
              SizedBox(
                width: 120,
                child: _buildRiskGauge(alert.riskScore),
              ),
              SizedBox(
                width: 180,
                child: Text(
                  alert.detectedAt,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                ),
              ),
              SizedBox(
                width: 140,
                child: _buildStatusBadge(alert.status),
              ),
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    _rowActionIcon(Icons.manage_search_rounded, Colors.blueAccent, () => _showInvestigationDrawer(alert)),
                    const SizedBox(width: 8),
                    _rowActionIcon(Icons.block_flipped, Colors.redAccent, () => _showBlockDialog(alert)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = Colors.blueAccent;
    if (type.contains('Travel')) color = Colors.purpleAccent;
    if (type.contains('Suspicious')) color = Colors.orangeAccent;
    if (type.contains('Login')) color = Colors.tealAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        type,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _rowActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }


  Widget _buildRiskGauge(double score) {
    final color = score > 80 ? Colors.redAccent : score > 50 ? Colors.orangeAccent : Colors.tealAccent;
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                score.toInt().toString(),
                style: GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blueAccent;
    if (status == 'Open') color = Colors.redAccent;
    if (status == 'Investigation') color = Colors.orangeAccent;
    if (status == 'Resolved') color = Colors.greenAccent;
    if (status.contains('Positive')) color = Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }

  void _showBlockDialog(FraudAlert alert) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  'Block Account',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'This will immediately block ${alert.userName}\'s account and revoke all active sessions.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(fraudProvider.notifier).updateStatus(alert.id, 'Investigation');
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account blocked.')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInvestigationDrawer(FraudAlert alert) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Investigation',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) => _buildInvestigationUI(alert, dialogContext),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0.3, 0)).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)), child: child);
      },
    );
  }

  Widget _buildInvestigationUI(FraudAlert alert, BuildContext dialogContext) {
    return Material(
      color: const Color(0xFF0F172A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.white10)),
          color: Color(0xFF0F172A),
        ),
        child: Column(
          children: [
            _buildDrawerHeader(alert, dialogContext),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    _buildInvestigationHero(alert),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Behavioral Timeline'),
                        Tab(text: 'Linked Transactions'),
                        Tab(text: 'Internal Notes'),
                      ],
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.white24,
                      indicatorColor: Colors.blueAccent,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(padding: const EdgeInsets.all(40), child: _buildEvidenceTimeline(alert)),
                          const Center(child: Text('No linked transactions found.', style: TextStyle(color: Colors.white24))),
                          SingleChildScrollView(padding: const EdgeInsets.all(40), child: _buildAdminNotes()),
                        ],
                      ),
                    ),
                    _buildResolutionBar(alert, dialogContext),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationHero(FraudAlert alert) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildUserHeader(alert),
          const SizedBox(height: 24),
          _buildActionToolbar(alert),
        ],
      ),
    );
  }

  Widget _buildUserHeader(FraudAlert alert) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          child: Text(
            alert.userName[0],
            style: const TextStyle(fontSize: 24, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.userName,
                style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                alert.userEmail,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '3 previous alerts',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
        ),
        _buildRiskIndicator(alert.riskScore),
      ],
    );
  }

  Widget _buildRiskIndicator(double score) {
    final color = score > 80 ? Colors.redAccent : score > 50 ? Colors.orangeAccent : Colors.tealAccent;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            score.toInt().toString(),
            style: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(FraudAlert alert) {
    return Row(
      children: [
        _drawerActionBtn('Block Account', Colors.redAccent, Icons.do_not_disturb_on_outlined, () => _showBlockDialog(alert)),
        const SizedBox(width: 8),
        _drawerActionBtn('Require 2FA', Colors.orangeAccent, Icons.security_rounded, () {}),
        const SizedBox(width: 8),
        _drawerActionBtn('Whitelist', Colors.greenAccent, Icons.verified_user_outlined, () {}),
        const SizedBox(width: 8),
        _drawerActionBtn('False + ', Colors.white24, Icons.thumb_down_alt_outlined, () {}),
      ],
    );
  }

  Widget _drawerActionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceTimeline(FraudAlert alert) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _timelineStep('Login from Russia (new location)', '14:06', detail: 'IP: 198.51.100.12 • Chrome 124 • Windows', isCritical: true, icon: Icons.login_outlined),
        _timelineStep('Unusual transaction: ₹48,000', '12:06', detail: 'Merchant: Unknown • Card: **** 4291', icon: Icons.credit_card_outlined),
        _timelineStep('Login from 3 different devices in 1 hour', '10:06', detail: 'iPhone 15, Pixel 8, MacBook Pro', icon: Icons.devices_other_outlined),
        _timelineStep('Alert triggered', '08:06', detail: 'Automatic system detection', icon: Icons.notifications_active_outlined),
      ],
    );
  }

  Widget _timelineStep(String msg, String time, {String? detail, bool isCritical = false, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCritical ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: isCritical ? Colors.redAccent : Colors.white54),
              ),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.05)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.white24)),
                const SizedBox(height: 6),
                Text(msg, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail, style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVESTIGATION NOTES',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        TextField(
          maxLines: 8,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter internal notes about this investigation...',
            hintStyle: const TextStyle(color: Colors.white12, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }
  Widget _buildDrawerHeader(FraudAlert alert, BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.manage_search_rounded, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Case: ${alert.id.toUpperCase()}',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Investigation Protocol Alpha-9',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ],
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

  Widget _buildResolutionBar(FraudAlert alert, BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AdminButton(
              label: 'RESOLVE & CLOSE CASE',
              onPressed: () {
                ref.read(fraudProvider.notifier).updateStatus(alert.id, 'Resolved');
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.more_vert, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
