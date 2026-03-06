import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/dashboard_provider.dart';

enum TimeFrame { daily, weekly, monthly }

class TrendAnalysisChart extends ConsumerStatefulWidget {
  const TrendAnalysisChart({super.key});

  @override
  ConsumerState<TrendAnalysisChart> createState() => _TrendAnalysisChartState();
}

class _TrendAnalysisChartState extends ConsumerState<TrendAnalysisChart> {
  TimeFrame _selectedTimeFrame = TimeFrame.daily;
  bool _showRevenue = true;
  bool _showRentals = true;
  bool _showUsers = false;
  bool _showHealth = false;

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassSurface
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.glassBorder
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 500;
                      return isSmall
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderTitle(isDark),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildExportButton(metrics, isDark),
                                    _buildTimeFrameToggle(isDark),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHeaderTitle(isDark),
                                Row(
                                  children: [
                                    _buildExportButton(metrics, isDark),
                                    const SizedBox(width: 12),
                                    _buildTimeFrameToggle(isDark),
                                  ],
                                ),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildMetricToggle(
                        'Revenue',
                        AppColors.accentBlue,
                        _showRevenue,
                        (val) => setState(() => _showRevenue = val),
                        isDark,
                      ),
                      _buildMetricToggle(
                        'Rentals',
                        AppColors.primaryOrange,
                        _showRentals,
                        (val) => setState(() => _showRentals = val),
                        isDark,
                      ),
                      _buildMetricToggle(
                        'Users',
                        Colors.purple,
                        _showUsers,
                        (val) => setState(() => _showUsers = val),
                        isDark,
                      ),
                      _buildMetricToggle(
                        'Battery Health',
                        Colors.green,
                        _showHealth,
                        (val) => setState(() => _showHealth = val),
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: LineChart(
                      _buildMainData(metrics, isDark),
                      duration: const Duration(milliseconds: 250),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 800.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildHeaderTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Analysis',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last 30 days performance',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(DashboardMetrics metrics, bool isDark) {
    return InkWell(
      onTap: () => _exportToCSV(metrics),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.download_rounded,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              'Export',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToCSV(DashboardMetrics metrics) {
    // Generate CSV content for the selected timeframe
    final labels = _getSelectedData(
      metrics,
      'revenue',
    ).map((e) => e.label).toList();
    final revenue = _getSelectedData(
      metrics,
      'revenue',
    ).map((e) => e.value).toList();
    final rentals = _getSelectedData(
      metrics,
      'rentals',
    ).map((e) => e.value).toList();
    final users = _getSelectedData(
      metrics,
      'users',
    ).map((e) => e.value).toList();
    final health = _getSelectedData(
      metrics,
      'health',
    ).map((e) => e.value).toList();

    String csv = 'Label,Revenue (₹),Rentals,Users,Battery Health (%)\n';
    for (int i = 0; i < labels.length; i++) {
      csv +=
          '${labels[i]},${revenue[i]},${rentals[i]},${users[i]},${health[i]}\n';
    }

    // In a real app, we'd use path_provider and open_file or a web download blob.
    // For this simulation, we'll print the CSV to console and show a snackbar.
    debugPrint('Exporting CSV:\n$csv');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Trend data exported for ${_selectedTimeFrame.name} view',
        ),
        backgroundColor: AppColors.accentBlue,
      ),
    );
  }

  Widget _buildTimeFrameToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _timeFrameButton('Daily', TimeFrame.daily, isDark),
          _timeFrameButton('Weekly', TimeFrame.weekly, isDark),
          _timeFrameButton('Monthly', TimeFrame.monthly, isDark),
        ],
      ),
    );
  }

  Widget _timeFrameButton(String label, TimeFrame frame, bool isDark) {
    final isSelected = _selectedTimeFrame == frame;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeFrame = frame),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryOrange : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricToggle(
    String label,
    Color color,
    bool isActive,
    Function(bool) onToggle,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => onToggle(!isActive),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildMainData(DashboardMetrics metrics, bool isDark) {
    final revenueData = _getSelectedData(metrics, 'revenue');
    final rentalsData = _getSelectedData(metrics, 'rentals');
    final usersData = _getSelectedData(metrics, 'users');
    final healthData = _getSelectedData(metrics, 'health');

    // Calculate max Y based on selected and visible data
    double maxY = 0;
    if (_showRevenue) {
      maxY = revenueData.fold(
        maxY,
        (prev, e) => prev > e.value ? prev : e.value,
      );
    }
    if (_showRentals) {
      maxY = rentalsData.fold(
        maxY,
        (prev, e) => prev > e.value ? prev : e.value,
      );
    }
    if (_showUsers) {
      maxY = usersData.fold(maxY, (prev, e) => prev > e.value ? prev : e.value);
    }
    if (_showHealth) {
      maxY = healthData.fold(
        maxY,
        (prev, e) => prev > e.value ? prev : e.value,
      );
    }

    // Add 10% padding
    maxY = maxY == 0 ? 100 : maxY * 1.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _getXInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < revenueData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    revenueData[index].label,
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black38,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatYValue(value),
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        if (_showRevenue) _buildLine(revenueData, AppColors.accentBlue),
        if (_showRentals) _buildLine(rentalsData, AppColors.primaryOrange),
        if (_showUsers) _buildLine(usersData, Colors.purple),
        if (_showHealth) _buildLine(healthData, Colors.green),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => isDark ? Colors.grey[900]! : Colors.white,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              String label = '';
              String unit = '';
              if (spot.barIndex == 0 && _showRevenue) {
                label = 'Revenue';
                unit = '₹';
              } else if (spot.barIndex == 1 && _showRentals) {
                label = 'Rentals';
              } else if (spot.barIndex == 2 && _showUsers) {
                label = 'Users';
              } else if (spot.barIndex == 3 && _showHealth) {
                label = 'Health';
                unit = '%';
              }

              return LineTooltipItem(
                '$unit${spot.y.toInt().toString()}${unit == '%' ? '%' : ''}\n',
                GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<TrendDataPoint> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.value);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  List<TrendDataPoint> _getSelectedData(
    DashboardMetrics metrics,
    String metric,
  ) {
    switch (_selectedTimeFrame) {
      case TimeFrame.daily:
        if (metric == 'revenue') return metrics.dailyRevenue;
        if (metric == 'rentals') return metrics.dailyRentals;
        if (metric == 'users') return metrics.dailyUsers;
        return metrics.dailyHealth;
      case TimeFrame.weekly:
        if (metric == 'revenue') return metrics.weeklyRevenue;
        if (metric == 'rentals') return metrics.weeklyRentals;
        if (metric == 'users') return metrics.weeklyUsers;
        return metrics.weeklyHealth;
      case TimeFrame.monthly:
        if (metric == 'revenue') return metrics.monthlyRevenue;
        if (metric == 'rentals') return metrics.monthlyRentals;
        if (metric == 'users') return metrics.monthlyUsers;
        return metrics.monthlyHealth;
    }
  }

  double _getXInterval() {
    switch (_selectedTimeFrame) {
      case TimeFrame.daily:
        return 5;
      case TimeFrame.weekly:
        return 1;
      case TimeFrame.monthly:
        return 1;
    }
  }

  String _formatYValue(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}
