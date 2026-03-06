import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final List<double>? sparklineData;
  final String? subtitle;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
    this.sparklineData,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 600;

    return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(isSmall ? 16 : 24),
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
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: isSmall ? 13 : 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black54,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: isSmall ? 4 : 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                style: GoogleFonts.outfit(
                                  fontSize: isSmall ? 26 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: isSmall ? 10 : 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildAnimatedIcon(isDark, isSmall),
                    ],
                  ),
                  const Spacer(),
                  if (sparklineData != null && sparklineData!.isNotEmpty)
                    _buildSparkline(color, isSmall),
                  const SizedBox(height: 12),
                  _buildTrendSection(isDark, isSmall),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildAnimatedIcon(bool isDark, bool isSmall) {
    return Container(
          width: isSmall ? 44 : 54,
          height: isSmall ? 44 : 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: isSmall ? 20 : 24),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          delay: 2.seconds,
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.2),
        );
  }

  Widget _buildSparkline(Color color, bool isSmall) {
    return SizedBox(
      height: isSmall ? 32 : 40,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (sparklineData!.length - 1).toDouble(),
          minY: sparklineData!.reduce((a, b) => a < b ? a : b) * 0.95,
          maxY: sparklineData!.reduce((a, b) => a > b ? a : b) * 1.05,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: sparklineData!
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(bool isDark, bool isSmall) {
    final isUp = trend.startsWith('+');
    final trendColor = isUp ? AppColors.emeraldSuccess : AppColors.crimsonError;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: isSmall ? 4 : 6),
      margin: EdgeInsets.only(top: isSmall ? 6 : 12),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUp ? Icons.trending_up : Icons.trending_down,
              size: isSmall ? 12 : 14,
              color: trendColor,
            ),
            const SizedBox(width: 4),
            Text(
              trend,
              style: GoogleFonts.outfit(
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'vs last month',
              style: GoogleFonts.inter(
                fontSize: isSmall ? 9 : 10,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
