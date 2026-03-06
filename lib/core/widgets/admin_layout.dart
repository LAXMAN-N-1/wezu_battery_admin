import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../../features/auth/provider/auth_provider.dart';

/// Menu section data model
class MenuSection {
  final String id;
  final IconData icon;
  final String label;
  final String? route; // null = has children, no direct route
  final List<MenuItem> children;

  const MenuSection({
    required this.id,
    required this.icon,
    required this.label,
    this.route,
    this.children = const [],
  });
}

class MenuItem {
  final String label;
  final String route;

  const MenuItem({required this.label, required this.route});
}

/// All sidebar sections
const List<MenuSection> _menuSections = [
  MenuSection(
    id: 'dashboard',
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    route: '/dashboard',
    children: [
      MenuItem(label: 'Overview', route: '/dashboard'),
      MenuItem(label: 'Analytics', route: '/dashboard/analytics'),
    ],
  ),
  MenuSection(
    id: 'users',
    icon: Icons.people_outline,
    label: 'User Management',
    children: [
      MenuItem(label: 'All Users', route: '/users'),
      MenuItem(label: 'KYC Requests', route: '/users/kyc'),
      MenuItem(label: 'Roles & Permissions', route: '/users/roles'),
      MenuItem(label: 'Suspended Accounts', route: '/users/suspended'),
    ],
  ),
  MenuSection(
    id: 'fleet',
    icon: Icons.battery_charging_full_outlined,
    label: 'Fleet & Inventory',
    children: [
      MenuItem(label: 'All Batteries', route: '/fleet/batteries'),
      MenuItem(label: 'Stock Levels', route: '/fleet/stock'),
      MenuItem(label: 'Battery Health', route: '/fleet/health'),
      MenuItem(label: 'Audit Trail', route: '/fleet/audit'),
      MenuItem(label: 'Bulk Import/Export', route: '/fleet/bulk'),
    ],
  ),
  MenuSection(
    id: 'stations',
    icon: Icons.ev_station_outlined,
    label: 'Stations',
    children: [
      MenuItem(label: 'All Stations', route: '/stations'),
      MenuItem(label: 'Station Map', route: '/stations/map'),
      MenuItem(label: 'Performance', route: '/stations/performance'),
      MenuItem(label: 'Maintenance', route: '/stations/maintenance'),
    ],
  ),
  MenuSection(
    id: 'dealers',
    icon: Icons.handshake_outlined,
    label: 'Dealers',
    children: [
      MenuItem(label: 'All Dealers', route: '/dealers'),
      MenuItem(label: 'Registrations', route: '/dealers/registrations'),
      MenuItem(label: 'KYC & Verification', route: '/dealers/kyc'),
      MenuItem(label: 'Commissions', route: '/dealers/commissions'),
      MenuItem(label: 'Documents', route: '/dealers/documents'),
    ],
  ),
  MenuSection(
    id: 'rentals',
    icon: Icons.receipt_long_outlined,
    label: 'Rentals & Orders',
    children: [
      MenuItem(label: 'Active Rentals', route: '/rentals/active'),
      MenuItem(label: 'Rental History', route: '/rentals/history'),
      MenuItem(label: 'Battery Swaps', route: '/rentals/swaps'),
      MenuItem(label: 'Purchase Orders', route: '/rentals/purchases'),
      MenuItem(label: 'Late Fees', route: '/rentals/late-fees'),
    ],
  ),
  MenuSection(
    id: 'finance',
    icon: Icons.account_balance_outlined,
    label: 'Finance',
    children: [
      MenuItem(label: 'Revenue Dashboard', route: '/finance'),
      MenuItem(label: 'Transactions', route: '/finance/transactions'),
      MenuItem(label: 'Settlements', route: '/finance/settlements'),
      MenuItem(label: 'Invoices', route: '/finance/invoices'),
      MenuItem(label: 'Profit Analysis', route: '/finance/profit'),
    ],
  ),
  MenuSection(
    id: 'logistics',
    icon: Icons.local_shipping_outlined,
    label: 'Logistics',
    children: [
      MenuItem(label: 'Delivery Orders', route: '/logistics/orders'),
      MenuItem(label: 'Live Tracking', route: '/logistics/tracking'),
      MenuItem(label: 'Drivers', route: '/logistics/drivers'),
      MenuItem(label: 'Route Planner', route: '/logistics/routes'),
      MenuItem(label: 'Returns', route: '/logistics/returns'),
    ],
  ),
  MenuSection(
    id: 'fleet-ops',
    icon: Icons.settings_remote_outlined,
    label: 'Fleet Operations',
    children: [
      MenuItem(label: 'IoT Dashboard', route: '/fleet-ops/iot'),
      MenuItem(label: 'Geofencing', route: '/fleet-ops/geofence'),
      MenuItem(label: 'Telematics', route: '/fleet-ops/telematics'),
      MenuItem(label: 'Alerts & Alarms', route: '/fleet-ops/alerts'),
    ],
  ),
  MenuSection(
    id: 'bess',
    icon: Icons.bolt_outlined,
    label: 'BESS',
    children: [
      MenuItem(label: 'BESS Overview', route: '/bess'),
      MenuItem(label: 'Energy Monitoring', route: '/bess/monitoring'),
      MenuItem(label: 'Grid Integration', route: '/bess/grid'),
      MenuItem(label: 'Reports', route: '/bess/reports'),
    ],
  ),
  MenuSection(
    id: 'support',
    icon: Icons.support_agent_outlined,
    label: 'Support',
    children: [
      MenuItem(label: 'Tickets', route: '/support/tickets'),
      MenuItem(label: 'Knowledge Base', route: '/support/knowledge'),
      MenuItem(label: 'Team Performance', route: '/support/performance'),
    ],
  ),
  MenuSection(
    id: 'notifications',
    icon: Icons.notifications_active_outlined,
    label: 'Notifications',
    children: [
      MenuItem(label: 'Send Push', route: '/notifications/send'),
      MenuItem(label: 'Automated Triggers', route: '/notifications/triggers'),
      MenuItem(label: 'Notification Logs', route: '/notifications/logs'),
      MenuItem(label: 'SMS & Email Config', route: '/notifications/config'),
    ],
  ),
  MenuSection(
    id: 'cms',
    icon: Icons.article_outlined,
    label: 'CMS',
    children: [
      MenuItem(label: 'Blog Posts', route: '/cms/blogs'),
      MenuItem(label: 'FAQ Management', route: '/cms/faqs'),
      MenuItem(label: 'App Banners', route: '/cms/banners'),
      MenuItem(label: 'Legal Documents', route: '/cms/legal'),
      MenuItem(label: 'Media Library', route: '/cms/media'),
    ],
  ),
  MenuSection(
    id: 'audit',
    icon: Icons.shield_outlined,
    label: 'Audit & Security',
    children: [
      MenuItem(label: 'Audit Logs', route: '/audit/logs'),
      MenuItem(label: 'Fraud Detection', route: '/audit/fraud'),
      MenuItem(label: 'Security Settings', route: '/audit/security'),
    ],
  ),
  MenuSection(
    id: 'settings',
    icon: Icons.settings_outlined,
    label: 'Settings',
    children: [
      MenuItem(label: 'General', route: '/settings'),
      MenuItem(label: 'API Keys', route: '/settings/api-keys'),
      MenuItem(label: 'System Health', route: '/settings/health'),
    ],
  ),
];

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          _buildSidebar(context, ref),
          Expanded(
            child: Column(
              children: [
                _buildHeader(ref, title),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(selectedRouteProvider);
    final expandedSections = ref.watch(expandedSectionsProvider);

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          // Logo header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEZU Energy',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Admin Portal',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 8),

          // Scrollable menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final section in _menuSections) ...[
                  _buildSection(ref, section, currentRoute, expandedSections),
                ],
              ],
            ),
          ),

          // Sign out
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              onTap: () => ref.read(authProvider.notifier).logout(),
              dense: true,
              leading: Icon(Icons.logout_outlined, color: Colors.red.shade300, size: 18),
              title: Text(
                'Sign Out',
                style: GoogleFonts.inter(color: Colors.red.shade300, fontWeight: FontWeight.w500, fontSize: 13),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              hoverColor: Colors.red.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(WidgetRef ref, MenuSection section, String currentRoute, Set<String> expandedSections) {
    final bool isExpanded = expandedSections.contains(section.id);
    final bool isSectionActive = currentRoute.startsWith('/${section.id}') ||
        section.children.any((c) => currentRoute == c.route) ||
        (section.route != null && currentRoute == section.route);

    // For dashboard, handle the direct route matching
    if (section.id == 'dashboard') {
      final isDashActive = currentRoute.startsWith('/dashboard');
      return _buildSectionTile(ref, section, isDashActive, isExpanded);
    }

    return _buildSectionTile(ref, section, isSectionActive, isExpanded);
  }

  Widget _buildSectionTile(WidgetRef ref, MenuSection section, bool isActive, bool isExpanded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: ListTile(
            onTap: () {
              if (section.children.isNotEmpty) {
                ref.read(expandedSectionsProvider.notifier).toggle(section.id);
                // Navigate to first child
                if (!isExpanded && section.children.isNotEmpty) {
                  final firstRoute = section.children.first.route;
                  ref.read(selectedRouteProvider.notifier).state = firstRoute;
                  GoRouter.of(ref.context).go(firstRoute);
                }
              } else if (section.route != null) {
                ref.read(selectedRouteProvider.notifier).state = section.route!;
                GoRouter.of(ref.context).go(section.route!);
              }
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              section.icon,
              color: isActive ? Colors.blue.shade400 : Colors.white38,
              size: 19,
            ),
            title: Text(
              section.label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : Colors.white60,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
            trailing: section.children.length > 1
                ? Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white24,
                    size: 18,
                  )
                : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: isActive && !isExpanded ? Colors.blue.withOpacity(0.08) : Colors.transparent,
            hoverColor: Colors.white.withOpacity(0.03),
          ),
        ),

        // Submenu children
        if (isExpanded && section.children.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            child: Column(
              children: section.children.map((item) {
                final isChildActive = ref.watch(selectedRouteProvider) == item.route;
                return _buildChildItem(ref, item, isChildActive);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChildItem(WidgetRef ref, MenuItem item, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: ListTile(
        onTap: () {
          ref.read(selectedRouteProvider.notifier).state = item.route;
          GoRouter.of(ref.context).go(item.route);
        },
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        contentPadding: const EdgeInsets.only(left: 24),
        leading: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue.shade400 : Colors.white12,
          ),
        ),
        title: Text(
          item.label,
          style: GoogleFonts.inter(
            color: isActive ? Colors.blue.shade300 : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive ? Colors.blue.withOpacity(0.06) : Colors.transparent,
        hoverColor: Colors.white.withOpacity(0.03),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String title) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white54, size: 20),
            tooltip: 'Search',
          ),
          const SizedBox(width: 4),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.white54, size: 20),
                tooltip: 'Notifications',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(height: 28, width: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade600,
            child: const Text("L", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Laxman", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              Text("Super Admin", style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
