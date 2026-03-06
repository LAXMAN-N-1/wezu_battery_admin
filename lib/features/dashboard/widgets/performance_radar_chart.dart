import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';

class PerformanceRadarChart extends StatelessWidget {
  const PerformanceRadarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorder
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.circle,
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                    borderColor: AppColors.primaryOrange,
                    entryRadius: 2,
                    dataEntries: [
                      const RadarEntry(value: 3),
                      const RadarEntry(value: 4),
                      const RadarEntry(value: 2),
                      const RadarEntry(value: 5),
                      const RadarEntry(value: 3),
                      const RadarEntry(value: 4),
                    ],
                  ),
                  RadarDataSet(
                    fillColor: AppColors.accentBlue.withValues(alpha: 0.3),
                    borderColor: AppColors.accentBlue,
                    entryRadius: 2,
                    dataEntries: [
                      const RadarEntry(value: 4),
                      const RadarEntry(value: 2),
                      const RadarEntry(value: 5),
                      const RadarEntry(value: 3),
                      const RadarEntry(value: 4),
                      const RadarEntry(value: 2),
                    ],
                  ),
                ],
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 10,
                ),
                getTitle: (index, angle) {
                  const titles = ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'];
                  return RadarChartTitle(text: titles[index % titles.length]);
                },
                tickCount: 1,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                gridBorderData: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Income', AppColors.primaryOrange, isDark),
        const SizedBox(width: 20),
        _legendItem('Saving', AppColors.accentBlue, isDark),
      ],
    );
  }

  Widget _legendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
