import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/system_health_models.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

/// API Response Time line chart with P50 (blue) and P99 (orange) lines
/// plus a dashed 500ms threshold line
class ApiResponseTimeChart extends StatefulWidget {
  final List<ApiResponseTimePoint> data;
  const ApiResponseTimeChart({super.key, required this.data});

  @override
  State<ApiResponseTimeChart> createState() => _ApiResponseTimeChartState();
}

class _ApiResponseTimeChartState extends SafeState<ApiResponseTimeChart> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final responseTimeMaxY = _calculateResponseTimeMaxY();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'API Response Times',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _legendDot(Colors.blue, 'P50 (median)'),
                          const SizedBox(width: 16),
                          _legendDot(Colors.orange, 'P99'),
                          const SizedBox(width: 16),
                          _legendDot(Colors.red.withValues(alpha: 0.6), '500ms threshold'),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Icon(Icons.show_chart, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('API Response Times',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _legendDot(Colors.blue, 'P50 (median)'),
                  const SizedBox(width: 16),
                  _legendDot(Colors.orange, 'P99'),
                  const SizedBox(width: 16),
                  _legendDot(Colors.red.withValues(alpha: 0.6), '500ms threshold'),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Y-Axis
              SizedBox(
                width: 60,
                height: 260,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 1,
                    minY: 0,
                    maxY: responseTimeMaxY,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: 100,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('${value.toInt()}ms',
                              style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [const FlSpot(0, 0)],
                        show: false,
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable Chart Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 800,
                          maxWidth: max(800.0, constraints.maxWidth),
                        ),
                        child: SizedBox(
                          height: 260,
                          child: LineChart(
                            duration: Duration.zero,
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 100,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 3,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) {
                                      final hour = (now.hour - 23 + value.toInt()) % 24;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text('${hour.toString().padLeft(2, '0')}:00',
                                          style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 23,
                              minY: 0,
                              maxY: responseTimeMaxY,
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: 500,
                                    color: Colors.red.withValues(alpha: 0.8),
                                    strokeWidth: 2,
                                    dashArray: [8, 4],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.red.withValues(alpha: 0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      labelResolver: (_) => '500ms threshold',
                                    ),
                                  ),
                                ],
                              ),
                              lineTouchData: LineTouchData(
                                handleBuiltInTouches: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => const Color(0xFF334155),
                                  getTooltipItems: (spots) => spots.map((spot) {
                                    final isP50 = spot.barIndex == 0;
                                    return LineTooltipItem(
                                      '${isP50 ? "P50" : "P99"}: ${spot.y.toStringAsFixed(0)}ms',
                                      GoogleFonts.robotoMono(
                                        color: isP50 ? Colors.blue : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              lineBarsData: [
                                // P50 line
                                LineChartBarData(
                                  spots: widget.data.map((d) => FlSpot(d.hour.toDouble(), d.p50Ms)).toList(),
                                  isCurved: true,
                                  curveSmoothness: 0.4,
                                  preventCurveOverShooting: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                      radius: 3,
                                      color: Colors.blue,
                                      strokeWidth: 0,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withValues(alpha: 0.15),
                                  ),
                                ),
                                // P99 line
                                LineChartBarData(
                                  spots: widget.data.map((d) => FlSpot(d.hour.toDouble(), d.p99Ms)).toList(),
                                  isCurved: true,
                                  curveSmoothness: 0.4,
                                  color: Colors.orange,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                      radius: 3,
                                      color: Colors.orange,
                                      strokeWidth: 0,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.orange.withValues(alpha: 0.05),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateResponseTimeMaxY() {
    double max = 500;
    for (final d in widget.data) {
      if (d.p99Ms > max) max = d.p99Ms;
    }
    return (max * 1.2).ceilToDouble();
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

/// API Error Rate bar chart with red-highlighted high-error hours
class ErrorRateChart extends StatelessWidget {
  final List<ErrorRatePoint> data;
  final int threshold;

  const ErrorRateChart({
    super.key,
    required this.data,
    this.threshold = 8,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double errorRateMaxY = 5;
    for (final d in data) {
      if (d.errorCount > errorRateMaxY) errorRateMaxY = d.errorCount.toDouble();
    }
    errorRateMaxY = (errorRateMaxY * 1.3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'API Error Rate (per hour)',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Threshold: $threshold', style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('API Error Rate (per hour)',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Threshold: $threshold', style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Y-Axis
              SizedBox(
                width: 48,
                height: 260,
                child: BarChart(
                  BarChartData(
                    maxY: errorRateMaxY,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: (errorRateMaxY / 4).ceilToDouble().clamp(1, 100),
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('${value.toInt()}',
                              style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: Colors.transparent)]),
                    ],
                  ),
                ),
              ),
              // Scrollable Chart Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 800,
                          maxWidth: max(800.0, constraints.maxWidth),
                        ),
                        child: SizedBox(
                          height: 260,
                          child: BarChart(
                            duration: Duration.zero,
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: errorRateMaxY,
                              barTouchData: BarTouchData(
                                handleBuiltInTouches: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => const Color(0xFF334155),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final point = data[group.x.toInt()];
                                    final hour = (now.hour - 23 + point.hour) % 24;
                                    return BarTooltipItem(
                                      '${hour.toString().padLeft(2, '0')}:00\n${point.errorCount} errors\nTop: HTTP ${point.topErrorCode}',
                                      GoogleFonts.robotoMono(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: (errorRateMaxY / 4).ceilToDouble().clamp(1, 100),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx % 3 != 0 || idx >= data.length) return const SizedBox.shrink();
                                      final hour = (now.hour - 23 + data[idx].hour) % 24;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text('${hour.toString().padLeft(2, '0')}:00',
                                          style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10)),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: threshold.toDouble(),
                                    color: Colors.red.withValues(alpha: 0.4),
                                    strokeWidth: 1,
                                    dashArray: [6, 4],
                                  ),
                                ],
                              ),
                              barGroups: data.asMap().entries.map((entry) {
                                final i = entry.key;
                                final d = entry.value;
                                final isAbove = d.errorCount > threshold;
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: d.errorCount.toDouble(),
                                      color: isAbove
                                          ? Colors.red
                                          : d.errorCount == 0
                                              ? Colors.grey.withValues(alpha: 0.2)
                                              : Colors.green.withValues(alpha: 0.6),
                                      width: 8,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: errorRateMaxY,
                                        color: Colors.white.withValues(alpha: 0.02),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
