import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/repositories/stock_repository.dart';
import '../data/models/stock.dart';
import '../data/models/battery.dart' as bdata;
import '../../../core/widgets/admin_ui_components.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/battery_detail_drawer.dart';
import '../widgets/reorder_modal.dart';
import 'stock_levels_view.dart';

final stationDetailProvider = FutureProvider.family
    .autoDispose<StationStockDetail, int>((ref, stationId) {
      return ref.watch(stockRepositoryProvider).getStationDetail(stationId);
    });

class StationStockDetailView extends ConsumerStatefulWidget {
  final int stationId;
  const StationStockDetailView({super.key, required this.stationId});

  @override
  ConsumerState<StationStockDetailView> createState() =>
      _StationStockDetailViewState();
}

class _StationStockDetailViewState extends ConsumerState<StationStockDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _safeDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _safeDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

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

  void _showBatteryDialog(BuildContext context, Map<String, dynamic> b) {
    if (b['id'] == null) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Battery Details',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 450,
              child: BatteryDetailDrawer(
                battery: bdata.Battery(
                  id: b['id']?.toString() ?? '',
                  serialNumber: b['serial_number'] ?? '',
                  status: b['status'] ?? 'available',
                  healthPercentage: _safeDouble(b['health_percentage'], 100.0),
                  locationType: 'station',
                  cycleCount: 0,
                  totalCycles: 0,
                  updatedAt: _safeDate(b['updated_at']),
                  createdAt: _safeDate(b['updated_at']),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(stationDetailProvider(widget.stationId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: detailAsync.when(
          data: (detail) => Row(
            children: [
              Text(
                detail.station.stationName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (detail.station.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LOW STOCK',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Text(
            'Loading Station...',
            style: TextStyle(color: Colors.white),
          ),
          error: (_, __) =>
              const Text('Error', style: TextStyle(color: Colors.red)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 160,
              child: AdminButton(
                label: 'Create Reorder',
                onPressed: detailAsync.value != null
                    ? () {
                        showDialog(
                          context: context,
                          builder: (_) => ReorderModal(
                            station: detailAsync.value!.station,
                            forecast: detailAsync.value!.forecast,
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Batteries at Station'),
            Tab(text: 'Forecast'),
            Tab(text: 'Reorder History'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: detailAsync.when(
        data: (detail) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(detail),
              _buildBatteriesTab(detail),
              _buildForecastTab(detail),
              _buildReorderHistoryTab(detail),
              _buildSettingsTab(detail),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load detail: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(StationStockDetail detail) {
    final s = detail.station;
    final capacity = s.config?.maxCapacity ?? 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Available',
                  '${s.availableCount}',
                  Colors.green,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  'Rented',
                  '${s.rentedCount}',
                  const Color(0xFF3B82F6),
                  Icons.outbound,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  'Maintenance',
                  '${s.maintenanceCount}',
                  Colors.amber,
                  Icons.build,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  'Capacity Used',
                  '${s.utilizationPercentage.toInt()}%',
                  Colors.purple,
                  Icons.pie_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stock Health',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: s.availableCount / capacity,
                                backgroundColor: const Color(0xFF0F172A),
                                color: s.isLowStock ? Colors.red : Colors.green,
                                strokeWidth: 14,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${s.availableCount} / $capacity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Available slots',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ThresholdEditor(
                        stationId: s.stationId,
                        currentPoint: s.config?.reorderPoint ?? 10,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Container(
                  height: 330,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7-Day Utilization Trend',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildTrendChart(detail)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTab(StationStockDetail detail) {
    final f = detail.forecast;
    final isCritical =
        f.predictedStockoutDays != null && f.predictedStockoutDays! <= 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.query_stats,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Demand Forecast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildForecastRow(
                        'Based on last 30 days',
                        'avg ${f.avgRentalsPerDay.toStringAsFixed(1)} rentals/day',
                      ),
                      _buildForecastRow(
                        'Projected demand next 30 days',
                        '~${f.projectedDemand30d} rentals',
                      ),
                      const Divider(color: Color(0xFF334155), height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Predicted stockout in:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            f.predictedStockoutDays != null
                                ? '${f.predictedStockoutDays} days'
                                : 'Healthy',
                            style: TextStyle(
                              color: isCritical
                                  ? Colors.redAccent
                                  : Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.recommend, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Recommended Action',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Reorder Quantity',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${f.recommendedReorder} batteries',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (f.recommendedDate != null)
                              Text(
                                'Before ${DateFormat("MMM d, yyyy").format(f.recommendedDate!)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: AdminButton(
                                label: 'Create Reorder Request',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ReorderModal(
                                      station: detail.station,
                                      forecast: detail.forecast,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '30-Day Projection Chart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildForecastChart(detail)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteriesTab(StationStockDetail detail) {
    final batteries = detail.batteries;
    if (batteries.isEmpty) {
      return Center(
        child: Text(
          'No batteries assigned to this station',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0F172A).withValues(alpha: 0.5),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'Serial Number',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              DataColumn(
                label: Text('Status', style: TextStyle(color: Colors.white54)),
              ),
              DataColumn(
                label: Text('Health', style: TextStyle(color: Colors.white54)),
              ),
              DataColumn(
                label: Text('Type', style: TextStyle(color: Colors.white54)),
              ),
              DataColumn(
                label: Text(
                  'Last Updated',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              DataColumn(
                label: Text('Actions', style: TextStyle(color: Colors.white54)),
              ),
            ],
            rows: batteries.map((b) {
              final status = b['status'];
              final color = status == 'available'
                  ? Colors.green
                  : (status == 'rented'
                        ? const Color(0xFF3B82F6)
                        : Colors.amber);
              final health = _safeDouble(b['health_percentage'], 100.0);
              final healthColor = health > 80
                  ? Colors.green
                  : (health > 50 ? Colors.amber : Colors.red);

              return DataRow(
                cells: [
                  DataCell(
                    InkWell(
                      onTap: () => _showBatteryDialog(context, b),
                      child: Text(
                        b['serial_number'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: health / 100,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                healthColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${health.toInt()}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      b['type'] ?? 'Li-ion',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      b['updated_at'] != null
                          ? DateFormat(
                              'MMM d, HH:mm',
                            ).format(DateTime.parse(b['updated_at']))
                          : 'N/A',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.white54,
                          ),
                          onPressed: () => _showBatteryDialog(context, b),
                          tooltip: 'View Details',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Color(0xFF3B82F6),
                          ),
                          onPressed: () {
                            // Location transfer logic here
                          },
                          tooltip: 'Transfer Location',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(StationStockDetail detail) {
    return _SettingsTab(detail: detail);
  }

  Widget _buildForecastRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildConfigField moved to _SettingsTab for local use

  // --- Charts & Mock Tabs Implementations ---

  Widget _buildTrendChart(StationStockDetail detail) {
    final baseValues = detail.utilizationTrend;
    if (baseValues.isEmpty) return const Center(child: Text("No trend data"));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Today',
                ];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          final val = baseValues[i];
          final isHigh = val > 85;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: isHigh ? Colors.amber : const Color(0xFF3B82F6),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildForecastChart(StationStockDetail detail) {
    final startVal = detail.station.availableCount.toDouble();
    final dropRate = detail.forecast.avgRentalsPerDay;
    final threshold = (detail.station.config?.reorderPoint ?? 10).toDouble();
    final maxCapacity = (detail.station.config?.maxCapacity ?? 50).toDouble();

    List<FlSpot> spots = [];
    double? stockoutDay;
    double? reorderDay;

    for (int i = 0; i < 30; i++) {
      double val = startVal - (dropRate * i);
      if (val < 0) val = 0;
      spots.add(FlSpot(i.toDouble(), val));

      if (reorderDay == null && val <= threshold && val > 0) {
        reorderDay = i.toDouble();
      }
      if (stockoutDay == null && val <= 0.1) {
        stockoutDay = i.toDouble();
      }
    }

    final hardStop = 1.0 - (threshold / maxCapacity).clamp(0.0, 1.0);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxCapacity,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Day ${value.toInt() + 1}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                if (spot.x == reorderDay) return true;
                if (spot.x == stockoutDay) return true;
                return false;
              },
              getDotPainter: (spot, percent, barData, index) {
                final isStockout = spot.x == stockoutDay;
                return FlDotCirclePainter(
                  radius: 5,
                  color: isStockout ? Colors.red : Colors.amber,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, hardStop, hardStop, 1.0],
                colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.green.withValues(alpha: 0.2),
                  Colors.red.withValues(alpha: 0.2),
                  Colors.red.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: threshold,
              color: Colors.redAccent,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => 'Reorder Point ($threshold)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderHistoryTab(StationStockDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0F172A).withValues(alpha: 0.5),
            ),
            columns: const [
              DataColumn(
                label: Text('Date', style: TextStyle(color: Colors.white54)),
              ),
              DataColumn(
                label: Text(
                  'Quantity',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              DataColumn(
                label: Text('Status', style: TextStyle(color: Colors.white54)),
              ),
              DataColumn(
                label: Text('Trigger', style: TextStyle(color: Colors.white54)),
              ),
            ],
            rows: [
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      DateFormat('MMM d, yyyy').format(
                        DateTime.now().subtract(const Duration(days: 15)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const DataCell(
                    Text('20 units', style: TextStyle(color: Colors.white)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'DELIVERED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const DataCell(
                    Text(
                      'Automated (Stock < 10)',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      DateFormat('MMM d, yyyy').format(
                        DateTime.now().subtract(const Duration(days: 45)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const DataCell(
                    Text('10 units', style: TextStyle(color: Colors.white)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'DELIVERED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const DataCell(
                    Text(
                      'Manual Request',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTab extends ConsumerStatefulWidget {
  final StationStockDetail detail;
  const _SettingsTab({required this.detail});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late TextEditingController maxCapacityCtrl;
  late TextEditingController reorderPointCtrl;
  late TextEditingController reorderQtyCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;

  bool notifyEmail = true;
  bool notifySms = false;
  bool notifyApp = true;
  bool autoReorder = false;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = widget.detail.station.config;
    maxCapacityCtrl = TextEditingController(
      text: config?.maxCapacity.toString() ?? '50',
    );
    reorderPointCtrl = TextEditingController(
      text: config?.reorderPoint.toString() ?? '10',
    );
    reorderQtyCtrl = TextEditingController(
      text: config?.reorderQuantity.toString() ?? '20',
    );
    emailCtrl = TextEditingController(text: config?.managerEmail ?? '');
    phoneCtrl = TextEditingController(text: config?.managerPhone ?? '');
  }

  @override
  void dispose() {
    maxCapacityCtrl.dispose();
    reorderPointCtrl.dispose();
    reorderQtyCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() => isSaving = true);
    try {
      final config = StationStockConfig(
        maxCapacity: int.tryParse(maxCapacityCtrl.text) ?? 50,
        reorderPoint: int.tryParse(reorderPointCtrl.text) ?? 10,
        reorderQuantity: int.tryParse(reorderQtyCtrl.text) ?? 20,
        managerEmail: emailCtrl.text.isEmpty ? null : emailCtrl.text,
        managerPhone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
      );

      await ref
          .read(stockRepositoryProvider)
          .updateStationConfig(widget.detail.station.stationId, config);

      // Invalidate relevant providers to refresh data across tabs and dashboard
      ref.invalidate(stockStationsProvider);
      ref.invalidate(stationDetailProvider(widget.detail.station.stationId));
      ref.invalidate(stockOverviewProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget _buildConfigField(
    String label,
    String helper,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            helperText: helper,
            helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Station Stock Configuration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adjust thresholds to control when low-stock alerts are triggered and how many batteries are recommended for reordering. (FR-ADMIN-INV-002)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildConfigField(
                      'Max Capacity',
                      'Total physical slots',
                      maxCapacityCtrl,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildConfigField(
                      'Reorder Point',
                      'Alert threshold',
                      reorderPointCtrl,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildConfigField(
                      'Reorder Quantity',
                      'Qty to order when low',
                      reorderQtyCtrl,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildConfigField(
                      'Manager Email',
                      'Send low stock alerts to this email',
                      emailCtrl,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildConfigField(
                      'Manager Phone',
                      'Send SMS alerts to this number',
                      phoneCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Alert Methods & Automation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildToggle(
                    'Email Alerts',
                    notifyEmail,
                    (v) => setState(() => notifyEmail = v),
                  ),
                  const SizedBox(width: 24),
                  _buildToggle(
                    'SMS Alerts',
                    notifySms,
                    (v) => setState(() => notifySms = v),
                  ),
                  const SizedBox(width: 24),
                  _buildToggle(
                    'In-App Alerts',
                    notifyApp,
                    (v) => setState(() => notifyApp = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildToggle(
                'Automatically create reorder request when stock hits threshold',
                autoReorder,
                (v) => setState(() => autoReorder = v),
                isWide: true,
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: AdminButton(
                  label: isSaving ? 'Saving...' : 'Save Configuration',
                  onPressed: isSaving ? null : _saveConfig,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    Function(bool) onChanged, {
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdEditor extends ConsumerStatefulWidget {
  final int stationId;
  final int currentPoint;

  const _ThresholdEditor({required this.stationId, required this.currentPoint});

  @override
  ConsumerState<_ThresholdEditor> createState() => _ThresholdEditorState();
}

class _ThresholdEditorState extends ConsumerState<_ThresholdEditor> {
  bool _isEditing = false;
  late TextEditingController _ctrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentPoint.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final val = int.tryParse(_ctrl.text);
    if (val == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(stockRepositoryProvider);
      final currentDetail = ref
          .read(stationDetailProvider(widget.stationId))
          .valueOrNull;
      final currentConfig = currentDetail?.station.config;
      final newConfig = StationStockConfig(
        maxCapacity: currentConfig?.maxCapacity ?? 50,
        reorderPoint: val,
        reorderQuantity: currentConfig?.reorderQuantity ?? 20,
        managerEmail: currentConfig?.managerEmail,
        managerPhone: currentConfig?.managerPhone,
      );
      await repo.updateStationConfig(widget.stationId, newConfig);
      ref.invalidate(stationDetailProvider(widget.stationId));
      ref.invalidate(stockOverviewProvider);
      ref.invalidate(stockStationsProvider);
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threshold updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Threshold:', style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _save(),
              ),
            ),

            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: _save,
                tooltip: 'Save',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => setState(() => _isEditing = false),
                tooltip: 'Cancel',
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Reorder Point Threshold',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.currentPoint} batteries',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _isEditing = true),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
