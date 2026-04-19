// lib/features/battery_health/widgets/health_detail_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/health_models.dart';
import '../data/repositories/health_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

final batteryDetailProvider =
    FutureProvider.autoDispose.family<HealthBatteryDetail, String>((ref, batteryId) {
      return ref.watch(healthRepositoryProvider).getBatteryDetail(batteryId);
    });

class HealthDetailDrawer extends ConsumerStatefulWidget {
  final String batteryId;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const HealthDetailDrawer({
    super.key,
    required this.batteryId,
    required this.onClose,
    required this.onRefresh,
  });

  @override
  ConsumerState<HealthDetailDrawer> createState() => _HealthDetailDrawerState();
}

class _HealthDetailDrawerState extends ConsumerState<HealthDetailDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(batteryDetailProvider(widget.batteryId));

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            // Backdrop
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 100,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            // Drawer
            Container(
              width: 620,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                border: Border(
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(-10, 0),
                  ),
                ],
              ),
              child: detail.when(
                data: (d) => _buildDrawerContent(d),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().slideX(begin: 1, duration: 300.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildDrawerContent(HealthBatteryDetail d) {
    final healthColor = d.healthPercentage > 80
        ? const Color(0xFF10B981)
        : d.healthPercentage > 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white24,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.serialNumber,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statusBadge(d.status, const Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        _statusBadge(d.healthStatus.toUpperCase(), healthColor),
                      ],
                    ),
                  ],
                ),
              ),
              // Health Gauge
              Column(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: d.healthPercentage / 100,
                          strokeWidth: 5,
                          backgroundColor: healthColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(healthColor),
                        ),
                        Text(
                          '${d.healthPercentage.toInt()}%',
                          style: GoogleFonts.outfit(
                            color: healthColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 12,
                      ),
                      Text(
                        ' ${d.degradationRate}%/mo',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white38),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.white38,
            indicatorColor: const Color(0xFF3B82F6),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Health Overview'),
              Tab(text: 'Trends'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Alerts'),
              Tab(text: 'Raw Data'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(d),
              _buildTrendsTab(d),
              _buildMaintenanceTab(d),
              _buildAlertsTab(d),
              _buildRawDataTab(d),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ==================================================================
  // TAB 1 — HEALTH OVERVIEW
  // ==================================================================
  Widget _buildOverviewTab(HealthBatteryDetail d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telemetry Cards
          Row(
            children:
                [
                      _telemetryCard(
                        '⚡',
                        '${d.voltage?.toStringAsFixed(1) ?? '--'}V',
                        'Voltage',
                        const Color(0xFF3B82F6),
                      ),
                      _telemetryCard(
                        '🌡',
                        '${d.temperature?.toStringAsFixed(1) ?? '--'}°C',
                        'Temperature',
                        (d.temperature ?? 0) > 45
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                      ),
                      _telemetryCard(
                        '⚡',
                        '${d.internalResistance?.toStringAsFixed(1) ?? '--'}mΩ',
                        'Resistance',
                        const Color(0xFF8B5CF6),
                      ),
                      _telemetryCard(
                        '🔄',
                        '${d.chargeCycles ?? d.totalCycles}',
                        'Cycles',
                        const Color(0xFF06B6D4),
                      ),
                    ]
                    .map(
                      (w) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: w,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),

          // Charge Cycles Progress
          _sectionTitle('Charge Cycle Lifecycle'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.chargeCycles ?? d.totalCycles} / 2000 cycles used',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (d.chargeCycles ?? d.totalCycles) / 2000,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(
                      (d.chargeCycles ?? d.totalCycles) / 2000 > 0.75
                          ? const Color(0xFFEF4444)
                          : (d.chargeCycles ?? d.totalCycles) / 2000 > 0.5
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (d.estimatedRemainingCycles != null)
                  Text(
                    'Estimated remaining: ~${d.estimatedRemainingCycles} cycles (~${d.estimatedRemainingYears?.toStringAsFixed(1) ?? '?'} years)',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Health Breakdown
          _sectionTitle('Health Score Breakdown'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _healthFactor('⚡ Voltage Health', d.voltageHealth),
                const SizedBox(height: 12),
                _healthFactor('🌡 Temperature Health', d.temperatureHealth),
                const SizedBox(height: 12),
                _healthFactor('⚡ Resistance Health', d.resistanceHealth),
                const SizedBox(height: 12),
                _healthFactor('🔄 Cycle Health', d.cycleHealth),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  children: [
                    Text(
                      'Overall Composite:',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${d.healthPercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF3B82F6),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // End of Life Prediction
          if (d.degradationRate > 0) ...[
            _sectionTitle('Predicted End-of-Life'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'At current rate of ${d.degradationRate}%/month:',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (d.predictedFairDate != null)
                    _predictionRow(
                      'Reach 50% (fair)',
                      d.predictedFairDate!,
                      const Color(0xFFF59E0B),
                    ),
                  if (d.predictedEolDate != null)
                    _predictionRow(
                      'Reach 20% (EOL)',
                      d.predictedEolDate!,
                      const Color(0xFFEF4444),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _telemetryCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _healthFactor(String label, double value) {
    final color = value > 80
        ? const Color(0xFF10B981)
        : value > 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toInt()}%',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _predictionRow(String label, String date, Color color) {
    final dateStr = date.length > 10 ? date.substring(0, 10) : date;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // TAB 2 — TRENDS
  // ==================================================================
  Widget _buildTrendsTab(HealthBatteryDetail d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Health Degradation Curve'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            height: 280,
            decoration: _cardDecoration(),
            child: _buildDegradationChart(d.snapshots),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Voltage Trend'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            height: 200,
            decoration: _cardDecoration(),
            child: _buildVoltageChart(d.snapshots),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Temperature History'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            height: 200,
            decoration: _cardDecoration(),
            child: _buildTemperatureChart(d.snapshots),
          ),
          const SizedBox(height: 20),

          // Stats Summary
          _sectionTitle('90-Day Statistics'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _statRow(
                  'Min Health Recorded',
                  d.minHealth != null
                      ? '${d.minHealth!.toStringAsFixed(1)}%'
                      : '--',
                ),
                _statRow(
                  'Max Health Recorded',
                  d.maxHealth != null
                      ? '${d.maxHealth!.toStringAsFixed(1)}%'
                      : '--',
                ),
                _statRow(
                  'Average over 90 days',
                  d.avgHealth != null
                      ? '${d.avgHealth!.toStringAsFixed(1)}%'
                      : '--',
                ),
                _statRow(
                  'Fastest single-week drop',
                  d.fastestDrop != null
                      ? '${d.fastestDrop!.toStringAsFixed(1)}%'
                      : '--',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDegradationChart(List<HealthSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white38)),
      );
    }
    final spots = snapshots
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.healthPercentage))
        .toList();
    final minY =
        (snapshots
                    .map((s) => s.healthPercentage)
                    .reduce((a, b) => a < b ? a : b) -
                5)
            .clamp(0, 100)
            .toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 10,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 80,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
            HorizontalLine(
              y: 50,
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(1)}%',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF3B82F6),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF3B82F6).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageChart(List<HealthSnapshot> snapshots) {
    final voltageData = snapshots.where((s) => s.voltage != null).toList();
    if (voltageData.isEmpty) {
      return const Center(
        child: Text('No voltage data', style: TextStyle(color: Colors.white38)),
      );
    }
    final spots = voltageData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.voltage!))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.white.withValues(alpha: 0.04)),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(0)}V',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFF59E0B),
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 2.5,
                color: const Color(0xFFF59E0B),
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(List<HealthSnapshot> snapshots) {
    final tempData = snapshots.where((s) => s.temperature != null).toList();
    if (tempData.isEmpty) {
      return const Center(
        child: Text(
          'No temperature data',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.white.withValues(alpha: 0.04)),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}°',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: tempData.asMap().entries.map((e) {
          final temp = e.value.temperature!;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: temp,
                color: temp > 45
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                width: 12,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // TAB 3 — MAINTENANCE
  // ==================================================================
  Widget _buildMaintenanceTab(HealthBatteryDetail d) {
    final scheduled = d.maintenanceHistory
        .where((m) => m.status == 'scheduled' || m.status == 'in_progress')
        .toList();
    final completed = d.maintenanceHistory
        .where((m) => m.status == 'completed')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Upcoming / Active'),
          const SizedBox(height: 8),
          if (scheduled.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white12,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No maintenance scheduled',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...scheduled.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    Icon(
                      Icons.build_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.maintenanceType
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Date: ${m.scheduledDate.substring(0, 10)} • Priority: ${m.priority}',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(m.status, const Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),
          _sectionTitle('Maintenance History'),
          const SizedBox(height: 8),
          if (completed.isEmpty)
            Text(
              'No maintenance history',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
            )
          else
            ...completed.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.maintenanceType.replaceAll('_', ' '),
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (m.healthBefore != null && m.healthAfter != null)
                            Text(
                              'Health: ${m.healthBefore!.toStringAsFixed(0)}% → ${m.healthAfter!.toStringAsFixed(0)}% (+${(m.healthAfter! - m.healthBefore!).toStringAsFixed(0)}%)',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF10B981),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      m.completedAt?.substring(0, 10) ?? '--',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11,
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

  // ==================================================================
  // TAB 4 — ALERTS
  // ==================================================================
  Widget _buildAlertsTab(HealthBatteryDetail d) {
    if (d.activeAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No active health alerts',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: d.activeAlerts.length,
      itemBuilder: (context, i) {
        final a = d.activeAlerts[i];
        final sevColor = a.severity == 'critical'
            ? const Color(0xFFEF4444)
            : a.severity == 'warning'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF3B82F6);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sevColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sevColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    a.severity == 'critical'
                        ? Icons.error_rounded
                        : a.severity == 'warning'
                        ? Icons.warning_rounded
                        : Icons.info_outline_rounded,
                    color: sevColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(a.alertType.replaceAll('_', ' '), sevColor),
                  const Spacer(),
                  Text(
                    a.createdAt.substring(0, 10),
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                a.message,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _resolveAlert(a.id),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: Text(
                      'Resolve',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: BorderSide(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _resolveAlert(int alertId) async {
    try {
      await ref
          .read(healthRepositoryProvider)
          .resolveAlert(alertId, 'Resolved from admin panel');
      ref.invalidate(batteryDetailProvider(widget.batteryId));
      widget.onRefresh();
    } catch (e) {
      // ignore for now
    }
  }

  // ==================================================================
  // TAB 5 — RAW DATA
  // ==================================================================
  Widget _buildRawDataTab(HealthBatteryDetail d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('All Health Snapshots (${d.snapshots.length})'),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 14),
                label: Text(
                  'Export CSV',
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (d.snapshots.isEmpty)
            Text(
              'No snapshots recorded',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
            )
          else
            AdvancedCard(
              padding: EdgeInsets.zero,
              child: AdvancedTable(
                columns: const ['Date', 'Health%', 'Voltage', 'Temp', 'Resistance', 'Cycles', 'Source'],
                rows: d.snapshots.reversed.map((s) {
                  return [
                    Text(
                      s.recordedAt.length > 10 ? s.recordedAt.substring(0, 10) : s.recordedAt,
                      style: _tinyCell(),
                    ),
                    Text('${s.healthPercentage.toStringAsFixed(1)}%', style: _tinyCell()),
                    Text(s.voltage != null ? '${s.voltage!.toStringAsFixed(1)}V' : '--', style: _tinyCell()),
                    Text(s.temperature != null ? '${s.temperature!.toStringAsFixed(1)}°C' : '--', style: _tinyCell()),
                    Text(s.internalResistance != null ? '${s.internalResistance!.toStringAsFixed(1)}mΩ' : '--', style: _tinyCell()),
                    Text(s.chargeCycles?.toString() ?? '--', style: _tinyCell()),
                    _statusBadge(s.snapshotType, Colors.white24),
                  ];
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _tinyHeader() => GoogleFonts.inter(
    color: Colors.white38,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  TextStyle _tinyCell() =>
      GoogleFonts.inter(color: Colors.white54, fontSize: 11);

  // ==================================================================
  // HELPERS
  // ==================================================================
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    );
  }
}
