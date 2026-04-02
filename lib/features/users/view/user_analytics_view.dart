import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/repositories/analytics_repository.dart';

class UserAnalyticsView extends StatefulWidget {
  const UserAnalyticsView({super.key});

  @override
  State<UserAnalyticsView> createState() => _UserAnalyticsViewState();
}

class _UserAnalyticsViewState extends State<UserAnalyticsView> {
  final AnalyticsRepository _repository = AnalyticsRepository();
  List<Map<String, dynamic>> _loginHistory = [];
  List<Map<String, dynamic>> _rentalFrequency = [];
  Map<String, int> _deviceBreakdown = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logins = await _repository.getLoginHistory();
      final rentals = await _repository.getRentalFrequency();
      final devices = await _repository.getDeviceBreakdown();
      setState(() {
        _loginHistory = logins;
        _rentalFrequency = rentals;
        _deviceBreakdown = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'User analytics is unavailable: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Behavior Analytics', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Login patterns, rental frequency, and device usage insights', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              _buildSummaryCard('Daily Logins', _loginHistory.isNotEmpty ? (_loginHistory.last['logins']?.toString() ?? '0') : '0', '', Colors.blue, Icons.login),
              const SizedBox(width: 16),
              _buildSummaryCard('Data Points', _deviceBreakdown.values.fold<int>(0, (sum, value) => sum + value).toString(), '', Colors.green, Icons.people),
              const SizedBox(width: 16),
              _buildSummaryCard('Tracked Months', _rentalFrequency.length.toString(), '', Colors.purple, Icons.timer),
              const SizedBox(width: 16),
              _buildSummaryCard('Device Types', _deviceBreakdown.length.toString(), '', Colors.amber, Icons.replay),
            ],
          ),
          const SizedBox(height: 24),

          // Login history chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Login Activity (Last 30 Days)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, interval: 5,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= _loginHistory.length) return const SizedBox();
                            return Text('Day ${value.toInt() + 1}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 9));
                          },
                        )),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _loginHistory.asMap().entries.map((e) =>
                            FlSpot(e.key.toDouble(), (e.value['logins'] as num?)?.toDouble() ?? 0)
                          ).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.08)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Rental frequency
              Expanded(
                flex: 3,
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Rental Frequency', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: _rentalFrequency.asMap().entries.map((e) {
                              return BarChartGroupData(x: e.key, barRods: [
                                BarChartRodData(
                                  toY: (e.value['rentals'] as num?)?.toDouble() ?? 0,
                                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ]);
                            }).toList(),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true, reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                              )),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= _rentalFrequency.length) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(_rentalFrequency[value.toInt()]['month'] as String, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                                  );
                                },
                              )),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Device breakdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device Usage', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 30,
                            sections: _deviceBreakdown.entries.toList().asMap().entries.map((e) {
                              final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange];
                              return PieChartSectionData(
                                value: e.value.value.toDouble(),
                                color: colors[e.key % colors.length],
                                title: '${e.value.value}%',
                                titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                radius: 38,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_deviceBreakdown.entries.toList().asMap().entries.map((e) {
                        final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(e.value.key, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                              
                              Text('${e.value.value}%', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      })),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Login History Table
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Login Sessions', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.03)),
                    columns: const [
                      DataColumn(label: Text('User', style: TextStyle(color: Colors.white70))),
                      DataColumn(label: Text('IP Address', style: TextStyle(color: Colors.white70))),
                      DataColumn(label: Text('Device', style: TextStyle(color: Colors.white70))),
                      DataColumn(label: Text('Time', style: TextStyle(color: Colors.white70))),
                    ],
                    rows: [
                      _buildLoginRow('Murari Varma', '192.168.1.100', 'Chrome / Windows', '5 min ago'),
                      _buildLoginRow('Deepak Verma', '103.55.90.12', 'Firefox / Mac', '1 hour ago'),
                      _buildLoginRow('Neha Gupta', '172.20.10.5', 'Edge / Windows', '3 hours ago'),
                      _buildLoginRow('Rahul Sharma', '103.42.56.78', 'Android App', '5 hours ago'),
                      _buildLoginRow('Amit Patel', '192.168.0.88', 'iOS App', '8 hours ago'),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildLoginRow(String name, String ip, String device, String time) {
    return DataRow(cells: [
      DataCell(Text(name, style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      DataCell(Text(ip, style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 12))),
      DataCell(Text(device, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12))),
      DataCell(Text(time, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12))),
    ]);
  }

  Widget _buildSummaryCard(String title, String value, String change, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(change, style: GoogleFonts.inter(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
