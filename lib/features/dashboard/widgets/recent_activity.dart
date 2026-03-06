import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';

class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final activities = [
      {
        'icon': Icons.electric_scooter_rounded,
        'color': AppColors.accentBlue,
        'title': 'New Rental Started',
        'sub': 'Battery #B-2847 → Jubilee Hills',
        'time': '2m',
      },
      {
        'icon': Icons.payment_rounded,
        'color': AppColors.emeraldSuccess,
        'title': 'Payment Received',
        'sub': '₹299 from Rahul M.',
        'time': '5m',
      },
      {
        'icon': Icons.battery_alert_rounded,
        'color': AppColors.amberWarning,
        'title': 'Low Battery Alert',
        'sub': 'Banjara Hills → 15% left',
        'time': '10m',
      },
      {
        'icon': Icons.person_add_rounded,
        'color': AppColors.accentPurple,
        'title': 'New User Registered',
        'sub': 'Priya K. — Google Sign-In',
        'time': '18m',
      },
      {
        'icon': Icons.keyboard_return_rounded,
        'color': AppColors.primaryOrange,
        'title': 'Battery Returned',
        'sub': '#B-1023 → Hi Tec City',
        'time': '25m',
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
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.primaryOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      _buildLiveStatus(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...activities.map((a) => _activityRow(a, isDark)),
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

  Widget _buildLiveStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emeraldSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.emeraldSuccess,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.5, 1.5),
                duration: 800.ms,
              ),
          const SizedBox(width: 8),
          const Text(
            'Live',
            style: TextStyle(
              color: AppColors.emeraldSuccess,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> a, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (a['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              a['icon'] as IconData,
              color: a['color'] as Color,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['title'] as String,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  a['sub'] as String,
                  style: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${a['time']}',
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
