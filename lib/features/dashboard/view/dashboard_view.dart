import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/providers/auth_provider.dart';
import '../../locations/view/location_view.dart';
import '../../users/view/user_list_view.dart';
import '../../kyc/view/kyc_queue_view.dart';
import '../../stations/view/station_list_view.dart';
import '../../banners/view/banner_list_view.dart';
import '../../dashboard/view/dashboard_overview.dart';
import '../../roles/view/role_list_view.dart';
import '../../batteries/view/battery_list_view.dart';

import '../../../core/providers/dashboard_provider.dart';

// final navigationProvider = StateProvider<int>((ref) => 0); // Moved to provider file

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(
                'PowerFill',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: !isDesktop
          ? const Drawer(
              backgroundColor: Color(0xFF1E293B),
              child: _SideMenu(),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) 
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: const _SideMenu(),
            ),
          Expanded(
            child: Column(
              children: [
                if (selectedIndex == 0) _buildHeader(context, 'Dashboard Overview'),
                Expanded(child: _buildContent(selectedIndex)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none, color: Colors.white70),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return const DashboardOverview();
      case 1:
        return const LocationView();
      case 2:
        return const UserListView();
      case 3:
        return const KycQueueView();
      case 4:
        return const StationListView();
      case 5:
        return const BannerListView();
      case 6:
        return const RoleListView();
      case 7:
        return const BatteryListView();
      default:
        return Center(
          child: Text(
            'Module Coming Soon',
            style: TextStyle(color: Colors.white38),
          ),
        );
    }
  }
}

class _SideMenu extends ConsumerWidget {
  const _SideMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (Responsive.isDesktop(context))
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'PowerFill',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const SizedBox(height: 32), // Spacing for Drawer
          
        _buildNavItem(ref, 0, Icons.dashboard_outlined, 'Overview'),
        _buildNavItem(ref, 1, Icons.public_outlined, 'Locations'),
        _buildNavItem(ref, 2, Icons.people_outline, 'Users'),
        _buildNavItem(ref, 3, Icons.verified_user_outlined, 'KYC Verification'),
        _buildNavItem(ref, 4, Icons.ev_station_outlined, 'Stations'),
        _buildNavItem(ref, 5, Icons.campaign_outlined, 'Banners'),
        _buildNavItem(ref, 6, Icons.admin_panel_settings_outlined, 'Roles'),
        _buildNavItem(ref, 7, Icons.battery_charging_full_outlined, 'Batteries'),
        const Spacer(),
        _buildNavItem(
          ref, -1,
          Icons.logout_outlined, 
          'Sign Out', 
          onTap: () => ref.read(authProvider.notifier).logout(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNavItem(WidgetRef ref, int index, IconData icon, String label, {VoidCallback? onTap}) {
    final selectedIndex = ref.watch(navigationProvider);
    final isActive = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap ?? () {
          ref.read(navigationProvider.notifier).state = index;
          if (!Responsive.isDesktop(ref.context)) {
            Navigator.pop(ref.context); // Close drawer
          }
        },
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? Colors.blue.shade400 : Colors.white38,
          size: 20,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
      ),
    );
  }
}
