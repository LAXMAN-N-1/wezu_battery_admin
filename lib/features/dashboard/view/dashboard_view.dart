import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reorderables/reorderables.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/export_service.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/trend_analysis_chart.dart';
import '../widgets/recent_activity.dart';
import '../widgets/quick_insights.dart';
import '../widgets/battery_health_pie.dart';
import '../widgets/revenue_bar_chart.dart';
import '../widgets/conversion_funnel.dart';
import '../../../../core/theme/theme_provider.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  bool _isCustomizing = false;

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1100;

    return Stack(
      children: [
        _buildBackground(isDark),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 32,
                vertical: isMobile ? 24 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _buildHeader(isDark, metrics, screenWidth)
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideX(begin: -0.05, end: 0),
                  SizedBox(height: isMobile ? 24 : 40),

                  // ── KPI Cards ──
                  _buildMetricCards(constraints.maxWidth, metrics)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 800.ms)
                      .slideY(begin: 0.1, end: 0),
                  SizedBox(height: isMobile ? 24 : 40),

                  // ── Draggable Widgets ──
                  _buildDraggableLayout(constraints.maxWidth, metrics, isDark)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 800.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.deepBg, const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
            ),
          ),
          // Blurred Accents
          Positioned(
            top: -100,
            right: -100,
            child: _blurNode(
              250,
              AppColors.primaryOrange.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _blurNode(300, AppColors.accentBlue.withValues(alpha: 0.08)),
          ),
          Positioned(
            top: 400,
            left: 200,
            child: _blurNode(
              200,
              AppColors.accentPurple.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurNode(double size, Color color) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 10.seconds,
          curve: Curves.easeInOut,
        );
  }

  // ─────────────────────── HEADER ───────────────────────
  Widget _buildHeader(bool isDark, DashboardMetrics metrics, double width) {
    final isSmall = width < 700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is what is happening with your fleet today',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSmall) _buildActionButtons(isDark, metrics),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusIndicator(isDark, metrics),
          if (isSmall) ...[
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: _buildActionButtons(isDark, metrics),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isDark, DashboardMetrics metrics) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: metrics.isRefreshing
                ? AppColors.emeraldSuccess
                : AppColors.amberWarning,
            shape: BoxShape.circle,
            boxShadow: [
              if (metrics.isRefreshing)
                BoxShadow(
                  color: AppColors.emeraldSuccess.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          metrics.isRefreshing
              ? 'Real-time sync active · 10s interval'
              : 'Auto-refresh paused · Last updated ${_formatTime(metrics.lastUpdated)}',
          style: TextStyle(
            color: isDark ? Colors.white30 : Colors.black38,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, DashboardMetrics metrics) {
    return Row(
      children: [
        _actionButton(
          onPressed: () => setState(() => _isCustomizing = !_isCustomizing),
          icon: _isCustomizing
              ? Icons.check_rounded
              : Icons.dashboard_customize_rounded,
          label: _isCustomizing ? 'Save Layout' : 'Customize',
          color: _isCustomizing
              ? AppColors.emeraldSuccess
              : AppColors.accentPurple,
        ),
        const SizedBox(width: 12),
        _actionButton(
          onPressed: () => ref.read(dashboardProvider.notifier).toggleRefresh(),
          icon: metrics.isRefreshing
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: metrics.isRefreshing ? 'Pause' : 'Resume',
          color: AppColors.primaryOrange,
        ),
        const SizedBox(width: 12),
        _actionButton(
          onPressed: () async {
            final path = await ExportService.exportDashboardToCSV(metrics);
            if (mounted && path != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dashboard exported to: $path')),
              );
            }
          },
          icon: Icons.ios_share_rounded,
          label: 'Export',
          color: AppColors.accentBlue,
        ),
      ],
    );
  }

  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ─────────────────────── DRAGGABLE LAYOUT ───────────────────────
  Widget _buildDraggableLayout(
    double width,
    DashboardMetrics metrics,
    bool isDark,
  ) {
    final widgets = <String, Widget>{
      'trend': const TrendAnalysisChart(),
      'health': BatteryHealthPie(data: metrics.batteryHealthDistribution),
      'stations': const RevenueBarChart(),
      'funnel': const ConversionFunnel(),
      'activity': const RecentActivity(),
      'insights': const QuickInsights(),
    };

    final order = metrics.widgetLayout;

    // Width calculations
    final bigWidgetWidth = width > 1200 ? width * 0.73 : width;
    final smallWidgetWidth = width > 1200 ? width * 0.23 : width;

    List<Widget> children = order.map((key) {
      final isLarge = key == 'trend' || key == 'stations' || key == 'activity';
      return Container(
        key: ValueKey(key),
        width: isLarge ? bigWidgetWidth : smallWidgetWidth,
        height: isLarge ? 420 : 400,
        margin: EdgeInsets.only(bottom: width < 600 ? 16 : 24),
        child: Stack(
          children: [
            widgets[key]!,
            if (_isCustomizing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.accentPurple, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: AppColors.accentPurple,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();

    if (!_isCustomizing) {
      if (width > 1100) {
        // Desktop / Large Tablet Grid
        return Column(
          children: [
            SizedBox(
              height: 420,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: widgets['trend']!),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: widgets['health']!),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 480,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: widgets['stations']!),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: widgets['funnel']!),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 400,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: widgets['activity']!),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: widgets['insights']!),
                ],
              ),
            ),
          ],
        );
      }
      // Tablet / Mobile stack
      return Column(
        children: order.map((key) {
          final double h;
          if (key == 'trend' || key == 'stations') {
            h = 420;
          } else if (key == 'funnel') {
            h = 580;
          } else if (key == 'health') {
            h = 420;
          } else {
            // activity or insights - let them wrap or give enough room
            h = 400;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SizedBox(height: h, child: widgets[key]!),
          );
        }).toList(),
      );
    }

    return ReorderableWrap(
      spacing: 24,
      runSpacing: 24,
      onReorder: (oldIndex, newIndex) {
        final newOrder = List<String>.from(order);
        final item = newOrder.removeAt(oldIndex);
        newOrder.insert(newIndex, item);
        ref.read(dashboardProvider.notifier).updateLayout(newOrder);
      },
      children: children,
    );
  }

  // ─────────────────────── METRIC CARDS ───────────────────────
  Widget _buildMetricCards(double width, DashboardMetrics metrics) {
    bool isMobileView = width < 1100;

    final cards = [
      MetricCard(
        title: 'Total Rentals',
        value: '${metrics.totalRentals}',
        trend: '+12.1%',
        subtitle: 'Last 24 hours',
        icon: Icons.electric_scooter_rounded,
        color: AppColors.accentBlue,
        sparklineData: metrics.rentalTrend,
      ),
      MetricCard(
        title: 'Total Revenue',
        value: metrics.revenue,
        trend: '+8.5%',
        subtitle: 'This month',
        icon: Icons.currency_rupee_rounded,
        color: AppColors.emeraldSuccess,
        sparklineData: const [4.0, 4.2, 4.5, 4.3, 4.6, 4.8, 5.0],
      ),
      MetricCard(
        title: 'Active Users',
        value: '${metrics.activeUsers}',
        trend: '+24.0%',
        subtitle: 'Currently online',
        icon: Icons.people_rounded,
        color: AppColors.primaryOrange,
        sparklineData: const [800, 850, 820, 880, 910, 900, 950],
      ),
      MetricCard(
        title: 'Fleet Utilization',
        value: metrics.fleetUtilization,
        trend: '-2.0%',
        subtitle: 'Battery fleet',
        icon: Icons.battery_charging_full_rounded,
        color: AppColors.accentPurple,
        sparklineData: const [75, 78, 80, 79, 81, 80, 80],
      ),
    ];

    if (isMobileView) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: cards
              .map(
                (card) => Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: AspectRatio(aspectRatio: 1.2, child: card),
                ),
              )
              .toList(),
        ),
      );
    }

    int cols = width > 1200 ? 4 : 2;
    double spacing = 18;
    double ratio = width > 1200 ? 1.1 : 1.4;

    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: ratio,
      children: cards,
    );
  }
}
