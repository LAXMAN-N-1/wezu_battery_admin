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
          _buildRevenueByBatteryType(state.revenueByBatteryType),
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
    return Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
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
        
        PopupMenuButton<String>(
          onSelected: (type) => ref.read(analyticsProvider.notifier).exportReport(type),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'overview', child: Text('Overview Report')),
            const PopupMenuItem(value: 'trends', child: Text('Trends Report')),
            const PopupMenuItem(value: 'forecast', child: Text('Demand Forecast')),
            const PopupMenuItem(value: 'behavior', child: Text('User Behavior')),
          ],
          child: ElevatedButton.icon(
            onPressed: null, // Using PopupMenuButton's child
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Platform Trends',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
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
                    spots: (state.trends is Map && state.trends['data'] is List)
                        ? (state.trends['data'] as List).asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), (e.value['value'] ?? 0).toDouble());
                          }).toList()
                        : const [FlSpot(0, 0)],
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
          if (data is Map && data['steps'] is List)
            ...(data['steps'] as List).map((step) {
              final label = step['label']?.toString() ?? 'Unknown';
              final count = step['count']?.toString() ?? '0';
              final factor = (step['percentage'] ?? 0).toDouble() / 100.0;
              final color = step['label'] == 'Installs' ? Colors.blue : (step['label'] == 'Registrations' ? Colors.purple : Colors.green);
              return _buildFunnelStep(label, count, factor.clamp(0.0, 1.0), color);
            })
          else
            const Center(child: Text('No funnel data', style: TextStyle(color: Colors.white38))),
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
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              
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
          if (data is Map && data['metrics'] is List)
            ...(data['metrics'] as List).map((m) {
              return _buildBehaviorRow(
                m['label'] ?? 'Unknown',
                m['value'] ?? '0',
                m['label']?.toString().contains('Daily') == true ? Icons.timer_outlined : (m['label']?.toString().contains('Repeat') == true ? Icons.replay_outlined : (m['label']?.toString().contains('Peak') == true ? Icons.access_time_outlined : Icons.trending_up_outlined)),
              );
            })
          else if (data is Map)
            ...data.entries.map((e) => _buildBehaviorRow(e.key.replaceAll('_', ' ').toUpperCase(), e.value.toString(), Icons.analytics_outlined))
          else
            const Center(child: Text('No behavior data', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }

  Widget _buildBehaviorRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
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
                sections: (data is Map && data['distribution'] is List)
                    ? (data['distribution'] as List).map((d) {
                        final color = d['range']?.toString().contains('80') == true ? Colors.green : (d['range']?.toString().contains('60') == true ? Colors.yellow : (d['range']?.toString().contains('40') == true ? Colors.orange : Colors.red));
                        return PieChartSectionData(
                          color: color,
                          value: (d['percentage'] ?? 0).toDouble(),
                          title: '${(d['percentage'] ?? 0).toInt()}%',
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList()
                    : [],
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
          if (data is List)
            ...data.map((r) {
              return _buildRegionRow(
                r['region'] ?? r['city'] ?? 'Unknown',
                '₹${r['revenue'] ?? 0}',
                ((r['percentage'] ?? 0).toDouble() / 100.0).clamp(0.0, 1.0),
              );
            })
          else
            const Center(child: Text('No regional data', style: TextStyle(color: Colors.white38))),
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
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(city, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              
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
            rows: (data is List)
                ? data.map((s) {
                    return [
                      _stationText(s['name'] ?? 'N/A'),
                      _whiteText(s['total_rentals']?.toString() ?? '0'),
                      _whiteText('₹${s['total_revenue'] ?? 0}'),
                      _healthBadge('${(s['avg_health'] ?? 0).toInt()}%'),
                      StatusBadge(status: s['status'] ?? 'Active'),
                    ];
                  }).toList()
                : [],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByBatteryType(dynamic data) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Battery Type',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (data is List)
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: data.map((b) {
                return SizedBox(
                  width: 200,
                  child: _inventoryMetric(
                    b['battery_type'] ?? 'Unknown',
                    '₹${b['revenue'] ?? 0}',
                    Colors.purple.shade300,
                  ),
                );
              }).toList(),
            )
          else
            const Center(child: Text('No battery revenue data', style: TextStyle(color: Colors.white38))),
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
                    spots: (data is Map && data['forecast'] is List)
                        ? (data['forecast'] as List).asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), (e.value['value'] ?? 0).toDouble());
                          }).toList()
                        : [],
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
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'User Growth & Retention',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
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
                barGroups: (state.userGrowth is Map && state.userGrowth['data'] is List)
                    ? (state.userGrowth['data'] as List).asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [BarChartRodData(toY: (e.value['value'] ?? 0).toDouble(), color: Colors.blue, width: 20)],
                        );
                      }).toList()
                    : [],
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
          if (data is List)
            ...data.map((item) {
              final type = item['type']?.toString().toLowerCase() ?? 'info';
              final color = type == 'alert' || type == 'error' || type.contains('critical') ? Colors.red : Colors.blue;
              final icon = type == 'alert' || type == 'error' || type.contains('critical') ? Icons.warning_amber : (type.contains('update') ? Icons.sync : Icons.info_outline);
              return _activityItem(
                item['message'] ?? item['description'] ?? 'System action occurred',
                item['timestamp'] ?? item['time'] ?? 'Recently',
                icon,
                color: color,
              );
            })
          else
            const Center(child: Text('No recent activity', style: TextStyle(color: Colors.white38))),
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
          if (data is Map)
            ...data.entries.map((e) {
              final label = e.key.replaceAll('_', ' ').toUpperCase();
              final value = e.value.toString();
              final color = e.key.contains('use') ? Colors.green : (e.key.contains('charge') ? Colors.amber : (e.key.contains('maintenance') ? Colors.red : Colors.blue));
              return _inventoryMetric(label, value, color);
            })
          else
            const Center(child: Text('No inventory data', style: TextStyle(color: Colors.white38))),
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
