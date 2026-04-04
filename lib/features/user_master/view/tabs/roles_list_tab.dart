import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/role.dart';
import '../../data/providers/user_master_providers.dart';

class RolesListTab extends ConsumerWidget {
  final VoidCallback onEditRole;

  const RolesListTab({super.key, required this.onEditRole});

  /// Convert snake_case DB role name to Display Name
  String _displayRoleName(String dbName) {
    return dbName
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Color _getRoleColor(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin': return Colors.redAccent;
      case 'customer': return Colors.greenAccent;
      case 'dealer': return Colors.orangeAccent;
      case 'station_manager': return Colors.blueAccent;
      case 'finance_manager': return Colors.purpleAccent;
      case 'technician': return Colors.tealAccent;
      case 'logistics_manager': return Colors.cyanAccent;
      case 'support_agent': return Colors.amberAccent;
      case 'driver': return Colors.lightGreenAccent;
      case 'warehouse_manager': return Colors.indigoAccent;
      default: return Colors.blueGrey;
    }
  }

  IconData _getRoleIcon(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings;
      case 'customer': return Icons.person_outline;
      case 'dealer': return Icons.storefront;
      case 'station_manager': return Icons.location_city;
      case 'finance_manager': return Icons.account_balance;
      case 'technician': return Icons.build;
      case 'logistics_manager': return Icons.local_shipping;
      case 'support_agent': return Icons.headset_mic;
      case 'driver': return Icons.directions_car;
      case 'warehouse_manager': return Icons.warehouse;
      case 'inspector': return Icons.search;
      case 'franchise_owner': return Icons.business;
      case 'marketing_manager': return Icons.campaign;
      case 'analyst': return Icons.analytics;
      default: return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return rolesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading roles: $err', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(rolesProvider),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
      data: (roles) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRolesStats(roles),
              const SizedBox(height: 24),
              _buildRolesGrid(roles, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRolesStats(List<Role> roles) {
    int total = roles.length;
    int system = roles.where((r) => r.isSystemRole).length;
    int custom = total - system;
    int usersAssigned = roles.fold(0, (sum, r) => sum + r.userCount);

    return Row(
      children: [
        Expanded(child: _statCard('Total Roles', '$total', Icons.admin_panel_settings_outlined, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('System Roles', '$system', Icons.settings_applications_outlined, Colors.purple)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Custom Roles', '$custom', Icons.dashboard_customize_outlined, Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Users Assigned', '$usersAssigned', Icons.people_alt_outlined, Colors.green)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesGrid(List<Role> roles, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 230,
      ),
      itemCount: roles.length + 1, // +1 for "Create New Role" card
      itemBuilder: (context, index) {
        // Last card is the "Create New Role" card
        if (index == roles.length) {
          return _buildCreateRoleCard();
        }

        final role = roles[index];
        final displayName = _displayRoleName(role.name);
        final roleColor = _getRoleColor(role.name);
        final roleIcon = _getRoleIcon(role.name);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: role.isSystemRole ? roleColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              if (role.isSystemRole) BoxShadow(color: roleColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(roleIcon, color: roleColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: role.isSystemRole ? Colors.purple.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.isSystemRole ? 'System' : 'Custom',
                          style: TextStyle(color: role.isSystemRole ? Colors.purpleAccent : Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                    color: const Color(0xFF0F172A),
                    onSelected: (val) {
                      if (val == 'edit') onEditRole();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: Colors.blue), SizedBox(width: 8), Text('Edit Role', style: TextStyle(color: Colors.white))])),
                      if (!role.isSystemRole)
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(displayName, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  role.description.isNotEmpty ? role.description : 'System role — ${displayName.toLowerCase()} access level',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                ),
              ),
              const Divider(color: Colors.white10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text('${role.userCount} users', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Text('Created ${DateFormat('MMM yyyy').format(role.createdAt)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateRoleCard() {
    return GestureDetector(
      onTap: onEditRole,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.blueAccent, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Create New Role', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 8),
            const Text(
              'Define custom access levels\nfor your team members',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
