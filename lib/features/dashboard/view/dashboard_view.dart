import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/metric_card.dart';
import '../widgets/dashboard_chart.dart';
import '../widgets/station_ranking_list.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      // Added scroll for smaller screens
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Responsive Metric Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = width > 1200 ? 4 : (width > 800 ? 2 : 1);
              double childAspectRatio = width > 1200
                  ? 1.2
                  : (width > 800 ? 1.8 : 2.0);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true, // Important inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable grid scroll
                childAspectRatio: childAspectRatio,
                children: const [
                  MetricCard(
                    title: 'Total Rentals',
                    value: '1,284',
                    trend: '+12%',
                    icon: Icons.electric_scooter,
                    color: Colors.blue,
                  ),
                  MetricCard(
                    title: 'Total Revenue',
                    value: '₹4.2L',
                    trend: '+8.5%',
                    icon: Icons.currency_rupee,
                    color: Colors.green,
                  ),
                  MetricCard(
                    title: 'Active Users',
                    value: '856',
                    trend: '+24%',
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    title: 'Fleet Utilization',
                    value: '78%',
                    trend: '-2%',
                    icon: Icons.battery_charging_full,
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Main Chart Section
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return SizedBox(
                  height: 400,
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: const DashboardChart()),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: const StationRankingList(),
                      ),
                    ],
                  ),
                );
              } else {
                return Column(
                  children: [
                    const SizedBox(height: 300, child: DashboardChart()),
                    const SizedBox(height: 24),
                    const StationRankingList(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
