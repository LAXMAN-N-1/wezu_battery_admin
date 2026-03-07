import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../../features/auth/provider/auth_provider.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const AdminLayout({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarOpen = ref.watch(sidebarOpenProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1E293B),
          child: _buildSidebar(context, ref, isMobile: true),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // Sidebar or Navigation Rail
          if (isSidebarOpen) 
            isTablet 
              ? _buildRail(context, ref)
              : _buildSidebar(context, ref, isMobile: false),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildHeader(ref, title, showMenuButton: !isTablet),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: selectedIndex == -1 ? null : selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).state = index;
          final routes = [
            '/dashboard',
            '/inventory/batteries',
            '/stations',
            '/stations/monitor',
            '/users',
            '/finance',
            '/support',
          ];
          if (index < routes.length) {
            GoRouter.of(context).go(routes[index]);
          }
        },
        labelType: NavigationRailLabelType.none,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Icon(Icons.bolt, color: Colors.blue.shade600, size: 28),
        ),
        destinations: const [
          NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
          NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Fleet')),
          NavigationRailDestination(icon: Icon(Icons.ev_station_outlined), selectedIcon: Icon(Icons.ev_station), label: Text('Stations')),
          NavigationRailDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: Text('Monitor')),
          NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
          NavigationRailDestination(icon: Icon(Icons.attach_money_outlined), selectedIcon: Icon(Icons.attach_money), label: Text('Finance')),
          NavigationRailDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: Text('Support')),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref, {
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? double.infinity : 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: isMobile
            ? null
            : Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'PowerFill',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildNavItem(
            ref,
            0,
            Icons.dashboard_outlined,
            'Dashboard',
            '/dashboard',
            isMobile: isMobile,
          ),
          _buildNavItem(
            ref,
            1,
            Icons.inventory_2_outlined,
            'Fleet & Inventory',
            '/inventory/batteries',
            isMobile: isMobile,
          ),
          _buildNavItem(
            ref,
            2,
            Icons.ev_station_outlined,
            'Stations',
            '/stations',
            isMobile: isMobile,
          ),
          _buildNavItem(
            ref,
            3,
            Icons.monitor_heart_outlined,
            '📡 Monitor',
            '/stations/monitor',
            isMobile: isMobile,
          ),
          _buildNavItem(
            ref,
            4,
            Icons.people_outline,
            'Users',
            '/users',
            isMobile: isMobile,
          ),
          _buildNavItem(
            ref,
            5,
            Icons.attach_money_outlined,
            'Finance',
            '/finance',
            isMobile: isMobile,
          ),
          _buildNavItem(
            ref,
            6,
            Icons.support_agent_outlined,
            'Support',
            '/support',
            isMobile: isMobile,
          ),
          const Spacer(),
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Need Help?",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Check the docs",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text("Documentation"),
                    ),
                  ],
                ),
              ),
            ),
          _buildNavItem(
            ref,
            -1,
            Icons.logout_outlined,
            'Sign Out',
            '/login',
            isMobile: isMobile,
            onTap: () {
              if (isMobile) Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    WidgetRef ref,
    int index,
    IconData icon,
    String label,
    String route, {
    required bool isMobile,
    VoidCallback? onTap,
  }) {
    final selectedIndex = ref.watch(navigationProvider);
    final isActive = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap:
            onTap ??
            () {
              ref.read(navigationProvider.notifier).state = index;
              if (isMobile) {
                Navigator.pop(ref.context);
              }
              GoRouter.of(ref.context).go(route);
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
        tileColor: isActive
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String title, {bool showMenuButton = true}) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              onPressed: () => ref.read(sidebarOpenProvider.notifier).state = !ref
                  .read(sidebarOpenProvider.notifier)
                  .state,
              icon: const Icon(Icons.menu, color: Colors.white70),
            ),
          if (showMenuButton) const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white70),
          ),
          const SizedBox(width: 24),
          Container(
            height: 32,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 24),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade600,
            child: const Text(
              "A",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin User",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                "Super Admin",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
