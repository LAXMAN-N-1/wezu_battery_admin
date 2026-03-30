import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_themes.dart';

enum MetricCardType { large, small }

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String trend;
  final String? trendLabel;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final double? changeValue;
  final VoidCallback? onTap;
  final MetricCardType type;
  final List<double>? sparkline;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trend,
    this.trendLabel,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.changeValue,
    this.onTap,
    this.type = MetricCardType.large,
    this.sparkline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final parsed =
        changeValue ??
        double.tryParse(trend.replaceAll(RegExp('[^0-9.-]'), ''));
    final bool isPositive = parsed != null && parsed >= 0;
    
    if (isLoading) {
      return _buildLoading(colors);
    }

    final cardBg = Color.lerp(colors.cardBg, Colors.black, 0.05) ?? colors.cardBg;

    Widget content = Container(
      padding: EdgeInsets.all(type == MetricCardType.small ? 16 : 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: type == MetricCardType.large 
          ? _buildLargeLayout(colors, isPositive) 
          : _buildSmallLayout(colors),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildLargeLayout(AppColorsExtension colors, bool isPositive) {
    return Stack(
      children: [
        // Sparkline at the bottom (Bleed)
        if (sparkline != null && sparkline!.isNotEmpty)
          Positioned(
            bottom: -15,
            left: -20,
            right: -20,
            child: SizedBox(
              height: 50,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: sparkline!.reduce(math.min) * 0.9,
                  maxY: sparkline!.reduce(math.max) * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: sparkline!
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: color.withValues(alpha: 0.5),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Main Content
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon and Trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (trend.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPositive 
                            ? const Color(0xFF22C55E)
                            : colors.danger).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trend,
                        style: GoogleFonts.inter(
                          color: isPositive 
                              ? const Color(0xFF22C55E)
                              : colors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // Middle: Value
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Bottom: Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 10), // Space for sparkline bleed
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallLayout(AppColorsExtension colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(AppColorsExtension colors) {
    // Re-using the same structure but with empty containers
    if (type == MetricCardType.large) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(40, 40, colors),
                _shimmerBox(60, 24, colors),
              ],
            ),
            const Spacer(),
            _shimmerBox(120, 32, colors),
            const SizedBox(height: 8),
            _shimmerBox(80, 16, colors),
            const SizedBox(height: 10),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _shimmerBox(40, 40, colors),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerBox(60, 20, colors),
                const SizedBox(height: 4),
                _shimmerBox(40, 12, colors),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _shimmerBox(double w, double h, AppColorsExtension colors) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
