import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String trend;
  final String trendLabel;
  final IconData icon;
  final Color color;
  final List<double>? sparkData;
  final bool isLoading;
  final double? changeValue;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.trendLabel,
    required this.icon,
    required this.color,
    this.sparkData,
    this.isLoading = false,
    this.changeValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final parsed =
        changeValue ??
        double.tryParse(trend.replaceAll(RegExp('[^0-9.-]'), ''));
    final bool isPositive = parsed != null && parsed > 0;
    final bool isNeutral = parsed == null || parsed == 0;

    if (isLoading) {
      return _buildLoading(colors);
    }

    Widget content = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: colors.textTertiary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sparkData != null && sparkData!.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: sparkData!
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
                                  color.withValues(alpha: 0.3),
                                  color.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isNeutral
                        ? colors.textTertiary.withValues(alpha: 0.12)
                        : (isPositive ? colors.success : colors.danger).withValues(
                            alpha: 0.08,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNeutral
                            ? Icons.horizontal_rule_rounded
                            : isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color: isNeutral
                            ? colors.textTertiary
                            : (isPositive ? colors.success : colors.danger),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trend,
                        style: GoogleFonts.inter(
                          color: isNeutral
                              ? colors.textSecondary
                              : (isPositive ? colors.success : colors.danger),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trendLabel,
                          style: GoogleFonts.inter(
                            color: (isPositive ? colors.success : colors.danger)
                                .withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildLoading(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 32,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
              ),
            );
          },
      ),
    );
  }
}
