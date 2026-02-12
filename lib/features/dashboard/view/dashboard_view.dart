import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/provider/auth_provider.dart';
import '../../locations/view/location_view.dart';

final navigationProvider = StateProvider<int>((ref) => 0);

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Column(
              children: [
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
                ),
                _buildNavItem(ref, 0, Icons.dashboard_outlined, 'Overview'),
                _buildNavItem(ref, 1, Icons.public_outlined, 'Locations'),
                _buildNavItem(ref, 2, Icons.admin_panel_settings_outlined, 'Roles'),
                _buildNavItem(ref, 3, Icons.ev_station_outlined, 'Stations'),
                _buildNavItem(ref, 4, Icons.battery_charging_full_outlined, 'Batteries'),
                const Spacer(),
                _buildNavItem(
                  ref, -1,
                  Icons.logout_outlined, 
                  'Sign Out', 
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header (Optional, could be part of screens)
                if (selectedIndex == 0) _buildHeader('Dashboard Overview'),
                
                // Content
                Expanded(
                  child: _buildContent(selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
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
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return const Center(
          child: Text(
            'Welcome to PowerFill Admin Portal',
            style: TextStyle(color: Colors.white38),
          ),
        );
      case 1:
        return const LocationView();
      default:
        return Center(
          child: Text(
            'Module Coming Soon',
            style: TextStyle(color: Colors.white38),
          ),
        );
    }
  }

  Widget _buildNavItem(WidgetRef ref, int index, IconData icon, String label, {VoidCallback? onTap}) {
    final selectedIndex = ref.watch(navigationProvider);
    final isActive = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap ?? () => ref.read(navigationProvider.notifier).state = index,
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
        tileColor: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
      ),
    );
  }
}
