import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/station_provider.dart';
import '../../../core/providers/kyc_provider.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/providers/dashboard_provider.dart';

class DashboardOverview extends ConsumerStatefulWidget {
  const DashboardOverview({super.key});

  @override
  ConsumerState<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends ConsumerState<DashboardOverview> {
  @override
  void initState() {
    super.initState();
    // Trigger loads to ensure we have fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userListProvider.notifier).loadUsers();
      ref.read(stationProvider.notifier).loadStats();
      ref.read(kycProvider.notifier).loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userListProvider);
    final stationState = ref.watch(stationProvider);
    final kycState = ref.watch(kycProvider);

    // Calculate/Extract stats
    final totalUsers = userState.total;
    final activeStations = stationState.stats['active'] ?? 0;
    final totalStations = stationState.stats['total'] ?? 0;
    final pendingKyc = kycState.analytics['pending'] ?? 0;
    final totalSwaps = stationState.stats['total_swaps_today'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Stats Grid
          GridView.count(
            crossAxisCount: Responsive.isMobile(context) ? 1 : Responsive.isTablet(context) ? 2 : 4,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            shrinkWrap: true,
            childAspectRatio: Responsive.isMobile(context) ? 1.3 : 1.4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total Users', 
                totalUsers.toString(), 
                Icons.people_outline, 
                Colors.blue,
                onTap: () => ref.read(navigationProvider.notifier).state = 2, // Users Index
              ),
              _buildStatCard(
                'Online Stations', 
                '$activeStations / $totalStations', 
                Icons.ev_station_outlined, 
                Colors.green,
                onTap: () => ref.read(navigationProvider.notifier).state = 4, // Stations Index
              ),
              _buildStatCard(
                'Pending KYC', 
                pendingKyc.toString(), 
                Icons.verified_user_outlined, 
                Colors.orange,
                onTap: () => ref.read(navigationProvider.notifier).state = 3, // KYC Index
              ),
              _buildStatCard(
                'Today\'s Swaps', 
                totalSwaps.toString(), 
                Icons.battery_charging_full_outlined, 
                Colors.purple,
                onTap: () => ref.read(navigationProvider.notifier).state = 7, // Batteries Index (or Stations)
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Recent Activity Section (Mocked for now)
          Text(
            'Recent System Activity',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (c, i) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    child: Icon(Icons.notifications_none, color: Colors.blue.shade400, size: 20),
                  ),
                  title: Text(
                    'System Alert ${index + 1}',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Station STN-${100+index} reported a minor fault.',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                  ),
                  trailing: Text(
                    '${index + 2}m ago',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: Colors.white.withValues(alpha: 0.1), size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
