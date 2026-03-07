import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _selectedPeriod = 'Last 30 Days';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              _buildHeaderRow(),
              const SizedBox(height: 24),

              // Row 1: 4 primary KPI cards
              _buildPrimaryKPIs(),
              const SizedBox(height: 16),

              // Row 2: 4 secondary KPI cards
              _buildSecondaryKPIs(),
              const SizedBox(height: 28),

              // Row 3: Revenue chart + Battery health donut
              _buildChartsRow(),
              const SizedBox(height: 24),

              // Row 4: Station performance + Recent activity + Quick actions
              _buildBottomRow(),
              const SizedBox(height: 24),

              // Row 5: Top Stations Table
              _buildTopStationsTable(),
            ],
          ),
        );
      },
    );
  }

  // ============================
  // HEADER ROW
  // ============================
  Widget _buildHeaderRow() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Laxman 👋',
              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what\'s happening with your platform today.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
        const Spacer(),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.expand_more, color: Colors.white54, size: 18),
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
          items: ['Today', 'Last 7 Days', 'Last 30 Days', 'This Quarter', 'This Year']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedPeriod = v!),
        ),
      ),
    );
  }

  // ============================
  // PRIMARY KPIs (Row 1)
  // ============================
  Widget _buildPrimaryKPIs() {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _kpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Total Revenue',
            value: '₹12.4L',
            trend: '+18.2%',
            trendUp: true,
            icon: Icons.currency_rupee,
            gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
            sparkData: [2, 5, 3, 8, 6, 9, 11, 8, 12],
          ),
          _kpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Active Rentals',
            value: '2,847',
            trend: '+12.5%',
            trendUp: true,
            icon: Icons.electric_bolt,
            gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            sparkData: [4, 6, 5, 8, 7, 9, 8, 11, 10],
          ),
          _kpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Total Users',
            value: '15,234',
            trend: '+24.8%',
            trendUp: true,
            icon: Icons.people_alt,
            gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
            sparkData: [3, 4, 5, 6, 8, 7, 9, 11, 14],
          ),
          _kpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Fleet Utilization',
            value: '84.2%',
            trend: '+3.1%',
            trendUp: true,
            icon: Icons.battery_charging_full,
            gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            sparkData: [6, 7, 5, 8, 7, 6, 8, 9, 8],
          ),
        ],
      );
    });
  }

  // ============================
  // SECONDARY KPIs (Row 2)
  // ============================
  Widget _buildSecondaryKPIs() {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _miniKpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Active Stations',
            value: '124',
            icon: Icons.ev_station,
            color: const Color(0xFF06B6D4),
          ),
          _miniKpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Active Dealers',
            value: '47',
            icon: Icons.handshake_outlined,
            color: const Color(0xFFEC4899),
          ),
          _miniKpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Avg. Battery Health',
            value: '91%',
            icon: Icons.health_and_safety,
            color: const Color(0xFF22C55E),
          ),
          _miniKpiCard(
            width: constraints.maxWidth > 1200 ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            title: 'Open Tickets',
            value: '23',
            icon: Icons.support_agent,
            color: const Color(0xFFF97316),
          ),
        ],
      );
    });
  }

  // ============================
  // CHARTS ROW
  // ============================
  Widget _buildChartsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1200) {
        return SizedBox(
          height: 400,
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildRevenueChart()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildBatteryHealthDonut()),
            ],
          ),
        );
      } else {
        return Column(
          children: [
            SizedBox(height: 400, child: _buildRevenueChart()),
            const SizedBox(height: 20),
            SizedBox(height: 400, child: _buildBatteryHealthDonut()),
          ],
        );
      }
    });
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenue & Rentals', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              _chartLegend('Revenue', const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _chartLegend('Rentals', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 200,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        if (value.toInt() >= 1 && value.toInt() <= 12) {
                          return Text(months[value.toInt()], style: GoogleFonts.inter(color: Colors.white30, fontSize: 11));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value / 1000).toStringAsFixed(0)}K', style: GoogleFonts.inter(color: Colors.white30, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1, maxX: 12, minY: 0, maxY: 1000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 220), FlSpot(2, 300), FlSpot(3, 380),
                      FlSpot(4, 350), FlSpot(5, 500), FlSpot(6, 480),
                      FlSpot(7, 620), FlSpot(8, 700), FlSpot(9, 680),
                      FlSpot(10, 780), FlSpot(11, 850), FlSpot(12, 920),
                    ],
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF3B82F6).withValues(alpha: 0.15), const Color(0xFF3B82F6).withValues(alpha: 0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 180), FlSpot(2, 250), FlSpot(3, 320),
                      FlSpot(4, 290), FlSpot(5, 420), FlSpot(6, 400),
                      FlSpot(7, 530), FlSpot(8, 590), FlSpot(9, 560),
                      FlSpot(10, 650), FlSpot(11, 720), FlSpot(12, 800),
                    ],
                    isCurved: true,
                    color: const Color(0xFF8B5CF6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.1), const Color(0xFF8B5CF6).withValues(alpha: 0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF334155),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = spot.barIndex == 0 ? 'Revenue' : 'Rentals';
                        return LineTooltipItem(
                          '$label: ₹${spot.y.toInt()}',
                          GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryHealthDonut() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Battery Health', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Fleet distribution by health %', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections: [
                      PieChartSectionData(
                        value: 62, color: const Color(0xFF22C55E), radius: 28,
                        title: '62%', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: 24, color: const Color(0xFFF59E0B), radius: 24,
                        title: '24%', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: 10, color: const Color(0xFF3B82F6), radius: 22,
                        title: '10%', titleStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: 4, color: const Color(0xFFEF4444), radius: 20,
                        title: '4%', titleStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('5,420', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Total', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _healthLegend('Excellent (90-100%)', const Color(0xFF22C55E), '3,360'),
          const SizedBox(height: 6),
          _healthLegend('Good (70-89%)', const Color(0xFFF59E0B), '1,301'),
          const SizedBox(height: 6),
          _healthLegend('Fair (50-69%)', const Color(0xFF3B82F6), '542'),
          const SizedBox(height: 6),
          _healthLegend('Poor (<50%)', const Color(0xFFEF4444), '217'),
        ],
      ),
    );
  }

  // ============================
  // BOTTOM ROW
  // ============================
  Widget _buildBottomRow() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1200) {
        return SizedBox(
          height: 380,
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildStationPerformanceChart()),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _buildRecentActivity()),
            ],
          ),
        );
      } else {
        return Column(
          children: [
            SizedBox(height: 380, child: _buildStationPerformanceChart()),
            const SizedBox(height: 20),
            SizedBox(height: 500, child: _buildRecentActivity()),
          ],
        );
      }
    });
  }

  Widget _buildStationPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Station Revenue (Top 5)', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('This month', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 200,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('₹${v.toInt()}K', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) {
                        const names = ['HYD-01', 'BLR-02', 'MUM-03', 'DEL-04', 'CHN-05'];
                        if (v.toInt() < names.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(names[v.toInt()], style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _barGroup(0, 180, const Color(0xFF3B82F6)),
                  _barGroup(1, 145, const Color(0xFF8B5CF6)),
                  _barGroup(2, 120, const Color(0xFF06B6D4)),
                  _barGroup(3, 95, const Color(0xFFF59E0B)),
                  _barGroup(4, 72, const Color(0xFFEC4899)),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF334155),
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      return BarTooltipItem('₹${rod.toY.toInt()}K', GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      _ActivityItem(icon: Icons.person_add, color: const Color(0xFF22C55E), title: 'New User Registration', subtitle: 'Raj Kumar verified via Aadhaar e-KYC', time: '2 min ago'),
      _ActivityItem(icon: Icons.electric_bolt, color: const Color(0xFF3B82F6), title: 'Battery Rental Started', subtitle: 'Battery #WZ-4821 rented at HYD-01 station', time: '8 min ago'),
      _ActivityItem(icon: Icons.swap_horiz, color: const Color(0xFF8B5CF6), title: 'Battery Swap Completed', subtitle: 'User Priya S. swapped at BLR-02 station', time: '15 min ago'),
      _ActivityItem(icon: Icons.warning_amber, color: const Color(0xFFF59E0B), title: 'Low Stock Alert', subtitle: 'Station MUM-03 below 10% capacity (3 batteries)', time: '22 min ago'),
      _ActivityItem(icon: Icons.payment, color: const Color(0xFF10B981), title: 'Payment Received', subtitle: '₹2,500 from dealer commission settlement', time: '35 min ago'),
      _ActivityItem(icon: Icons.handshake, color: const Color(0xFFEC4899), title: 'Dealer Application', subtitle: 'New dealer registration from Chennai', time: '1 hr ago'),
      _ActivityItem(icon: Icons.health_and_safety, color: const Color(0xFFEF4444), title: 'Battery Health Alert', subtitle: 'Battery #WZ-1092 health dropped below 50%', time: '1.5 hr ago'),
      _ActivityItem(icon: Icons.support_agent, color: const Color(0xFFF97316), title: 'Support Ticket Resolved', subtitle: 'Ticket #1847 resolved by Agent Suresh', time: '2 hr ago'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Activity', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E))),
                    const SizedBox(width: 6),
                    Text('Live', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
              itemBuilder: (context, index) {
                final a = activities[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: a.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(a.icon, color: a.color, size: 18),
                  ),
                  title: Text(a.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(a.subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                  trailing: Text(a.time, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // TOP STATIONS TABLE
  // ============================
  Widget _buildTopStationsTable() {
    final stations = [
      ['HYD-01', 'Hyderabad Central', '4,520', '₹1.8L', '92%', '4.8'],
      ['BLR-02', 'Bangalore Koramangala', '3,890', '₹1.45L', '88%', '4.7'],
      ['MUM-03', 'Mumbai Andheri West', '3,210', '₹1.2L', '85%', '4.6'],
      ['DEL-04', 'Delhi Connaught Place', '2,950', '₹95K', '78%', '4.5'],
      ['CHN-05', 'Chennai T. Nagar', '2,440', '₹72K', '82%', '4.4'],
      ['PUN-06', 'Pune Hinjewadi', '2,100', '₹68K', '80%', '4.3'],
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Top Performing Stations', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text('View All', style: GoogleFonts.inter(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _tableHeader('Station ID', flex: 1),
                _tableHeader('Location', flex: 2),
                _tableHeader('Rentals', flex: 1),
                _tableHeader('Revenue', flex: 1),
                _tableHeader('Utilization', flex: 1),
                _tableHeader('Rating', flex: 1),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Table rows
          ...stations.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: i < stations.length - 1
                    ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i < 3 ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 11, color: i < 3 ? const Color(0xFF3B82F6) : Colors.white38, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s[0], style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(s[1], style: GoogleFonts.inter(fontSize: 13, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text(s[2], style: GoogleFonts.inter(fontSize: 13, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text(s[3], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40, height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: int.parse(s[4].replaceAll('%', '')) / 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation(
                                int.parse(s[4].replaceAll('%', '')) > 85
                                    ? const Color(0xFF22C55E)
                                    : int.parse(s[4].replaceAll('%', '')) > 70
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s[4], style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(s[5], style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================
  // HELPER WIDGETS
  // ============================
  Widget _kpiCard({
    required double width,
    required String title,
    required String value,
    required String trend,
    required bool trendUp,
    required IconData icon,
    required List<Color> gradient,
    required List<double> sparkData,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendUp ? Icons.trending_up : Icons.trending_down, size: 12, color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(trend, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
            const SizedBox(height: 12),
            // Mini sparkline
            SizedBox(
              height: 30,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: (sparkData.reduce((a, b) => a < b ? a : b)) - 1,
                  maxY: (sparkData.reduce((a, b) => a > b ? a : b)) + 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: sparkData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: gradient[0].withValues(alpha: 0.8),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [gradient[0].withValues(alpha: 0.2), gradient[0].withValues(alpha: 0.0)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniKpiCard({required double width, required String title, required String value, required IconData icon, required Color color}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _healthLegend(String label, Color color, String count) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white54))),
        Text(count, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 200, color: Colors.white.withValues(alpha: 0.02)),
        ),
      ],
    );
  }

  Widget _tableHeader(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});
}
