import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/role.dart';
import '../../data/providers/user_master_providers.dart';

class RolesListTab extends ConsumerWidget {
  final VoidCallback onEditRole;

  const RolesListTab({super.key, required this.onEditRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return rolesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
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
        mainAxisExtent: 220,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: role.isSystemRole ? Colors.purple.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              if (role.isSystemRole) BoxShadow(color: Colors.purple.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: role.isSystemRole ? Colors.purple.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.isSystemRole ? 'System Role' : 'Custom Role',
                      style: TextStyle(color: role.isSystemRole ? Colors.purpleAccent : Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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
              const SizedBox(height: 16),
              Text(role.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(role.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
              const Spacer(),
              const Divider(color: Colors.white10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
}
