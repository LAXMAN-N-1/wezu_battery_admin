import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/dashboard_provider.dart';

class ConversionFunnel extends ConsumerWidget {
  const ConversionFunnel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final stages = metrics.funnelStages;

    return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 600 ? 16 : 28,
              ),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark, MediaQuery.of(context).size.width),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: stages.length,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) => _buildDropOff(
                        stages[index].count,
                        stages[index + 1].count,
                        isDark,
                        MediaQuery.of(context).size.width,
                      ),
                      itemBuilder: (context, index) {
                        final stage = stages[index];
                        final progress = stage.count / stages[0].count;

                        return _buildStageRow(
                          stage,
                          progress,
                          isDark,
                          MediaQuery.of(context).size.width,
                        );
                      },
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

  Widget _buildHeader(bool isDark, double width) {
    final isMobile = width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversion Funnel',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 20 : 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'User journey & drop-off analysis',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStageRow(
    FunnelStage stage,
    double progress,
    bool isDark,
    double width,
  ) {
    final isMobile = width < 600;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: isMobile ? 4 : 3,
              child: Text(
                stage.label,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: isMobile ? 6 : 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${stage.count}',
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${(progress * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      valueColor: AlwaysStoppedAnimation<Color>(stage.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropOff(int current, int next, bool isDark, double width) {
    final isMobile = width < 600;
    final dropOff = 100 - (next / current * 100);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.only(
        left: isMobile ? 30 : (current > 1000 ? 50 : 80),
      ),
      child: Row(
        children: [
          Container(
            width: 1,
            height: isMobile ? 12 : 20,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.south_rounded,
            size: 12,
            color: AppColors.crimsonError.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${dropOff.toStringAsFixed(1)}% drop-off',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.crimsonError.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
