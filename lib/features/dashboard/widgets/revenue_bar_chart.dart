import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/dashboard_provider.dart';

enum RevenueSort { revenueDesc, revenueAsc, name, volume }

enum RevenueDimension { station, batteryType }

class RevenueBarChart extends ConsumerStatefulWidget {
  const RevenueBarChart({super.key});

  @override
  ConsumerState<RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends ConsumerState<RevenueBarChart> {
  RevenueDimension _dimension = RevenueDimension.station;
  RevenueSort _sort = RevenueSort.revenueDesc;
  bool _isVertical = true;

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
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildControls(isDark),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _dimension == RevenueDimension.station
                        ? _buildStationChart(metrics.stationRevenue, isDark)
                        : _buildBatteryChart(
                            metrics.batteryTypeRevenue,
                            isDark,
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

  Widget _buildHeader(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;
        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitle(isDark),
              const SizedBox(height: 16),
              _buildDimensionToggle(isDark),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildHeaderTitle(isDark), _buildDimensionToggle(isDark)],
        );
      },
    );
  }

  Widget _buildHeaderTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Analytics',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dimension == RevenueDimension.station
              ? 'Revenue distribution by station'
              : 'Revenue distribution by battery type',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dimensionButton('Stations', RevenueDimension.station, isDark),
          _dimensionButton('Batteries', RevenueDimension.batteryType, isDark),
        ],
      ),
    );
  }

  Widget _dimensionButton(String label, RevenueDimension dim, bool isDark) {
    final isSelected = _dimension == dim;
    return GestureDetector(
      onTap: () => setState(() => _dimension = dim),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.accentBlue : Colors.white)
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
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Row(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<RevenueSort>(
            value: _sort,
            dropdownColor: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            items: const [
              DropdownMenuItem(
                value: RevenueSort.revenueDesc,
                child: Text('Revenue High-Low'),
              ),
              DropdownMenuItem(
                value: RevenueSort.revenueAsc,
                child: Text('Revenue Low-High'),
              ),
              DropdownMenuItem(
                value: RevenueSort.name,
                child: Text('Sort by Name'),
              ),
              DropdownMenuItem(
                value: RevenueSort.volume,
                child: Text('Sort by Volume'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _sort = val);
            },
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => _isVertical = !_isVertical),
          icon: Icon(
            _isVertical
                ? Icons.align_horizontal_left_rounded
                : Icons.align_vertical_bottom_rounded,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          tooltip: _isVertical ? 'Switch to Horizontal' : 'Switch to Vertical',
        ),
      ],
    );
  }

  Widget _buildStationChart(List<StationRevenue> data, bool isDark) {
    final sortedData = List<StationRevenue>.from(data);
    switch (_sort) {
      case RevenueSort.revenueDesc:
        sortedData.sort((a, b) => b.revenue.compareTo(a.revenue));
        break;
      case RevenueSort.revenueAsc:
        sortedData.sort((a, b) => a.revenue.compareTo(b.revenue));
        break;
      case RevenueSort.name:
        sortedData.sort((a, b) => a.name.compareTo(b.name));
        break;
      case RevenueSort.volume:
        sortedData.sort((a, b) => b.volume.compareTo(a.volume));
        break;
    }

    // Limit to top 10 for station view
    final displayData = sortedData.take(10).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            displayData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (spot) =>
                isDark ? Colors.grey[900]! : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = displayData[groupIndex];
              return BarTooltipItem(
                '${station.name}\n',
                GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '₹${(station.revenue / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(
                      color: isDark ? AppColors.accentBlue : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '\nVol: ${station.volume}',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < displayData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayData[index].name.substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: displayData.asMap().entries.map((entry) {
          final isTop3 = entry.key < 3;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.revenue,
                color: isTop3
                    ? AppColors.accentBlue
                    : AppColors.accentBlue.withValues(alpha: 0.5),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY:
                      displayData
                          .map((e) => e.revenue)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBatteryChart(List<BatteryTypeRevenue> data, bool isDark) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) * 1.5,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (spot) =>
                isDark ? Colors.grey[900]! : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final battery = data[groupIndex];
              return BarTooltipItem(
                '${battery.type}\n',
                GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '₹${(battery.revenue / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(
                      color: battery.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].type.split(' ')[0],
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 9,
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.revenue,
                color: entry.value.color,
                width: 40,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
