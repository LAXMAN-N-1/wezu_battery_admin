import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/provider/auth_provider.dart';

class MenuItem {
  final String label;
  final String route;

  const MenuItem({required this.label, required this.route});
}

class MenuSection {
  final String id;
  final IconData icon;
  final String label;
  final String? route; // null = has children, no direct route
  final List<MenuItem> children;
  final List<String>? allowedRoles; // null = all logged-in users

  const MenuSection({
    required this.id,
    required this.icon,
    required this.label,
    this.route,
    this.children = const [],
    this.allowedRoles,
  });
}

const List<MenuSection> _allMenuSections = [
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
    id: 'user-master',
    icon: Icons.people_outline,
    label: 'User Master',
    allowedRoles: [
      'super_admin',
      'superadmin',
      'admin',
      'operations_admin',
      'security_admin',
    ],
    children: [
      MenuItem(label: 'All Users', route: '/user-master'),
      MenuItem(label: 'Create User', route: '/user-master/create'),
      MenuItem(label: 'Add / Edit User', route: '/user-master/edit'),
      MenuItem(label: 'Roles & Permissions', route: '/user-master/roles'),
      MenuItem(label: 'Admin Groups', route: '/user-master/groups'),
      MenuItem(label: 'Access Logs', route: '/user-master/logs'),
      MenuItem(label: 'Bulk Import/Export', route: '/user-master/bulk'),
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
    allowedRoles: ['super_admin', 'superadmin', 'finance'],
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
    allowedRoles: ['super_admin', 'superadmin', 'admin'],
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
    allowedRoles: ['super_admin', 'superadmin'],
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
    allowedRoles: ['super_admin', 'superadmin', 'admin'],
    children: [
      MenuItem(label: 'General', route: '/settings'),
      MenuItem(label: 'API Keys', route: '/settings/api-keys'),
      MenuItem(label: 'System Health', route: '/settings/health'),
    ],
  ),
];

final sidebarMenuProvider = Provider<List<MenuSection>>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  // Extract roles string or list.
  final dynamic roleRaw =
      user?['role'] ?? user?['roles'] ?? user?['current_role'];

  List<String> userRoles = [];
  if (roleRaw is String) {
    userRoles.add(roleRaw.toLowerCase().trim());
  } else if (roleRaw is List) {
    userRoles.addAll(roleRaw.map((e) => e.toString().toLowerCase().trim()));
  }

  // Fallback: If roles is somehow completely empty but user is logged in,
  // we assume a base-level access (or superadmin if is_superuser is true).
  final isSuperuser =
      user?['is_superuser'] == true || user?['isSuperuser'] == true;
  if (isSuperuser && !userRoles.contains('superadmin')) {
    userRoles.add('superadmin');
  }

  return _allMenuSections.where((section) {
    if (section.allowedRoles == null || section.allowedRoles!.isEmpty) {
      return true; // No restrictions
    }

    // Check if the user has any of the allowed roles
    return userRoles.any(
      (r) => section.allowedRoles!.map((a) => a.toLowerCase()).contains(r),
    );
  }).toList();
});
