import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../provider/analytics_provider.dart';
import '../../../core/widgets/admin_ui_components.dart';

class UserAnalyticsView extends ConsumerStatefulWidget {
  const UserAnalyticsView({super.key});

  @override
  ConsumerState<UserAnalyticsView> createState() => _UserAnalyticsViewState();
}

class _UserAnalyticsViewState extends ConsumerState<UserAnalyticsView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading analytics',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(analyticsProvider.notifier).loadAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildKpiCards(state.overview),
          const SizedBox(height: 24),
          _buildTrendsSection(state),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildConversionFunnel(state.conversionFunnel)),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildUserBehavior(state.userBehavior)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildBatteryHealth(state.batteryHealth)),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildRevenueByRegion(state.revenueByRegion)),
            ],
          ),
          const SizedBox(height: 24),
          _buildTopStations(state.topStations),
          const SizedBox(height: 24),
          _buildDemandForecast(state.demandForecast),
          const SizedBox(height: 24),
          _buildUserGrowth(state),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildRecentActivity(state.recentActivity)),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildInventoryStatus(state.inventoryStatus)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Analytics',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Platform-wide insights and performance metrics',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => ref.read(analyticsProvider.notifier).exportReport('overview'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            foregroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> overview) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Active Users',
            value: overview['active_users']?.toString() ?? '0',
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'Total Rentals',
            value: overview['total_rentals']?.toString() ?? '0',
            icon: Icons.directions_bike_outlined,
            delay: const Duration(milliseconds: 100),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'Revenue Today',
            value: '₹${overview['revenue_today']?.toString() ?? '0'}',
            icon: Icons.account_balance_wallet_outlined,
            delay: const Duration(milliseconds: 200),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'Avg. Rental Duration',
            value: overview['avg_duration']?.toString() ?? '0m',
            icon: Icons.timer_outlined,
            delay: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection(AnalyticsState state) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Platform Trends',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildPeriodSelector(
                state.trendsPeriod,
                (p) => ref.read(analyticsProvider.notifier).changeTrendsPeriod(p),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Mocking timeline labels
                        return Text(
                          '${value.toInt()}',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(2, 5), FlSpot(4, 4), FlSpot(6, 8), FlSpot(8, 6)],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.1),
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

  Widget _buildConversionFunnel(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Funnel',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildFunnelStep('Installs', '1,200', 1.0, Colors.blue),
          _buildFunnelStep('Registrations', '850', 0.7, Colors.purple),
          _buildFunnelStep('First Rental', '420', 0.35, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(String label, String count, double widthFactor, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Text(count, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBehavior(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Behavior',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildBehaviorRow('Avg. Daily Usage', '42 mins', Icons.timer_outlined),
          _buildBehaviorRow('Repeat Customers', '76%', Icons.replay_outlined),
          _buildBehaviorRow('Peak Hour', '6 PM - 8 PM', Icons.access_time_outlined),
          _buildBehaviorRow('Churn Rate', '4.2%', Icons.trending_down_outlined),
        ],
      ),
    );
  }

  Widget _buildBehaviorRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade300, size: 18),
          ),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBatteryHealth(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battery Health Distribution',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: Colors.green, value: 65, title: '65%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: Colors.yellow, value: 20, title: '20%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: Colors.orange, value: 10, title: '10%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: Colors.red, value: 5, title: '5%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthLegend(),
        ],
      ),
    );
  }

  Widget _buildHealthLegend() {
    return Column(
      children: [
        _legendItem('Healthy (80-100%)', Colors.green),
        _legendItem('Good (60-80%)', Colors.yellow),
        _legendItem('Fair (40-60%)', Colors.orange),
        _legendItem('Poor (<40%)', Colors.red),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, color: color),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRevenueByRegion(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Region',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildRegionRow('Bangalore', '₹4,50,000', 0.9),
          _buildRegionRow('Hyderabad', '₹3,20,000', 0.65),
          _buildRegionRow('Chennai', '₹2,80,000', 0.55),
          _buildRegionRow('Pune', '₹1,50,000', 0.3),
        ],
      ),
    );
  }

  Widget _buildRegionRow(String city, String revenue, double widthFactor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(city, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Text(revenue, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStations(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Stations',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          AdvancedTable(
            columns: const ['Station Name', 'Rentals', 'Revenue', 'Avg Health', 'Status'],
            rows: [
              [_stationText('BLR-Central-01'), _whiteText('450'), _whiteText('₹54,000'), _healthBadge('92%'), const StatusBadge(status: 'Active')],
              [_stationText('BLR-Whitefield-04'), _whiteText('380'), _whiteText('₹42,500'), _healthBadge('88%'), const StatusBadge(status: 'Active')],
              [_stationText('HYD-Gachibowli-12'), _whiteText('310'), _whiteText('₹38,200'), _healthBadge('85%'), const StatusBadge(status: 'Maintenance')],
              [_stationText('CHE-OMR-08'), _whiteText('280'), _whiteText('₹32,100'), _healthBadge('90%'), const StatusBadge(status: 'Active')],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stationText(String text) => Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500));
  Widget _whiteText(String text) => Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13));
  Widget _healthBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: GoogleFonts.inter(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _buildDemandForecast(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30-Day Demand Forecast',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.05))),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 100), FlSpot(10, 150), FlSpot(20, 130), FlSpot(30, 200)],
                    isCurved: true,
                    color: Colors.amber,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.amber.withValues(alpha: 0.05)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowth(AnalyticsState state) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'User Growth & Retention',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildPeriodSelector(
                state.userGrowthPeriod,
                (p) => ref.read(analyticsProvider.notifier).changeUserGrowthPeriod(p),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 10, color: Colors.blue, width: 20)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 15, color: Colors.blue, width: 20)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 22, color: Colors.blue, width: 20)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 30, color: Colors.blue, width: 20)]),
                ],
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent System Activity',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _activityItem('Bulk stock update completed for BLR-CN-01', '2 mins ago', Icons.sync),
          _activityItem('New dealer registration pending review: EnerGrid', '15 mins ago', Icons.person_add),
          _activityItem('Critical battery temperature alert: BT-3042', '45 mins ago', Icons.warning_amber, color: Colors.red),
          _activityItem('Daily revenue report generated', '2 hours ago', Icons.description),
        ],
      ),
    );
  }

  Widget _activityItem(String msg, String time, IconData icon, {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 4),
                Text(time, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatus(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Status',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _inventoryMetric('Total Fleet', '4,250', Colors.blue),
          _inventoryMetric('In Use', '2,840', Colors.green),
          _inventoryMetric('Charging', '1,120', Colors.amber),
          _inventoryMetric('Maintenance', '290', Colors.red),
        ],
      ),
    );
  }

  Widget _inventoryMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(String current, Function(String) onSelect) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['daily', 'weekly', 'monthly'].map((p) {
          final isSelected = current == p;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p[0].toUpperCase() + p.substring(1),
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.38),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
