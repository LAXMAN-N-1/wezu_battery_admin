import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';

class QuickInsights extends ConsumerWidget {
  const QuickInsights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final insights = [
      {
        'icon': Icons.timer_outlined,
        'label': 'Avg. Rental Duration',
        'value': '2.4 hrs',
        'color': AppColors.accentBlue,
      },
      {
        'icon': Icons.star_outline_rounded,
        'label': 'Customer Rating',
        'value': '4.8★',
        'color': AppColors.amberWarning,
      },
      {
        'icon': Icons.battery_std_rounded,
        'label': 'Battery Health',
        'value': '94%',
        'color': AppColors.emeraldSuccess,
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Open Tickets',
        'value': '7',
        'color': AppColors.crimsonError,
      },
    ];

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: AppColors.accentBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quick Insights',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...insights.map((i) => _insightRow(i, isDark)),
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

  Widget _insightRow(Map<String, dynamic> i, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(i['icon'] as IconData, color: i['color'] as Color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                i['label'] as String,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              i['value'] as String,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
