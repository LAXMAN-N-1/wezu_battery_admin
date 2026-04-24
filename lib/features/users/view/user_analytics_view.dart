import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/parallel_load.dart';
import '../data/repositories/analytics_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

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
      final (logins, rentals, devices) = await ParallelLoad.trio(
        _repository.getLoginHistory(),
        _repository.getRentalFrequency(),
        _repository.getDeviceBreakdown(),
      );
      if (!mounted) return;
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
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xFFEF4444)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'User Behavior Analytics',
            subtitle:
                'Login patterns, rental frequency, and device usage insights',
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Summary cards
          Row(
                children: [
                  _buildSummaryCard(
                    'Daily Logins',
                    _loginHistory.isNotEmpty
                        ? (_loginHistory.last['logins']?.toString() ?? '0')
                        : '0',
                    const Color(0xFF3B82F6),
                    Icons.login,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Data Points',
                    _deviceBreakdown.values
                        .fold<int>(0, (sum, value) => sum + value)
                        .toString(),
                    const Color(0xFF22C55E),
                    Icons.people,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Tracked Months',
                    _rentalFrequency.length.toString(),
                    const Color(0xFF8B5CF6),
                    Icons.timer,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Device Types',
                    _deviceBreakdown.length.toString(),
                    const Color(0xFFF59E0B),
                    Icons.replay,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Login history chart
          AdvancedCard(
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login Activity (Last 30 Days)',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _loginHistory.length) {
                                return const SizedBox();
                              }
                              return Text(
                                'Day ${value.toInt() + 1}',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _loginHistory
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  (e.value['logins'] as num?)?.toDouble() ?? 0,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rental frequency
              Expanded(
                flex: 3,
                child: AdvancedCard(
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Rental Frequency',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: _rentalFrequency.asMap().entries.map((
                              e,
                            ) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY:
                                        (e.value['rentals'] as num?)
                                            ?.toDouble() ??
                                        0,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF8B5CF6),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 28,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text(
                                    '${value.toInt()}',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >=
                                        _rentalFrequency.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _rentalFrequency[value.toInt()]['month']
                                            as String,
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
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
                child: AdvancedCard(
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Usage',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 30,
                            sections: _deviceBreakdown.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((e) {
                                  final colors = [
                                    const Color(0xFF3B82F6),
                                    const Color(0xFF22C55E),
                                    const Color(0xFF8B5CF6),
                                    const Color(0xFFF59E0B),
                                  ];
                                  return PieChartSectionData(
                                    value: e.value.value.toDouble(),
                                    color: colors[e.key % colors.length],
                                    title: '${e.value.value}%',
                                    titleStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    radius: 38,
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_deviceBreakdown.entries.toList().asMap().entries.map(
                        (e) {
                          final colors = [
                            const Color(0xFF3B82F6),
                            const Color(0xFF22C55E),
                            const Color(0xFF8B5CF6),
                            const Color(0xFFF59E0B),
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors[e.key % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.value.key,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${e.value.value}%',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 24),

          // Login History Table
          AdvancedCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Recent Login Sessions',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.04),
                      height: 1,
                    ),
                    AdvancedTable(
                      columns: const ['User', 'IP Address', 'Device', 'Time'],
                      rows: [
                        _buildLoginRow(
                          'Murari Varma',
                          '192.168.1.100',
                          'Chrome / Windows',
                          '5 min ago',
                        ),
                        _buildLoginRow(
                          'Deepak Verma',
                          '103.55.90.12',
                          'Firefox / Mac',
                          '1 hour ago',
                        ),
                        _buildLoginRow(
                          'Neha Gupta',
                          '172.20.10.5',
                          'Edge / Windows',
                          '3 hours ago',
                        ),
                        _buildLoginRow(
                          'Rahul Sharma',
                          '103.42.56.78',
                          'Android App',
                          '5 hours ago',
                        ),
                        _buildLoginRow(
                          'Amit Patel',
                          '192.168.0.88',
                          'iOS App',
                          '8 hours ago',
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 250.ms)
              .slideY(begin: 0.05),
        ],
      ),
    );
  }

  List<Widget> _buildLoginRow(
    String name,
    String ip,
    String device,
    String time,
  ) {
    return [
      Text(name, style: TextStyle(color: Colors.white, fontSize: 13)),
      Text(
        ip,
        style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 12),
      ),
      Text(device, style: TextStyle(color: Colors.white54, fontSize: 12)),
      Text(time, style: TextStyle(color: Colors.white38, fontSize: 12)),
    ];
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
