import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/role_model.dart';
import '../data/repositories/rbac_repository.dart';

class RolesPermissionsView extends StatefulWidget {
  const RolesPermissionsView({super.key});

  @override
  State<RolesPermissionsView> createState() => _RolesPermissionsViewState();
}

class _RolesPermissionsViewState extends State<RolesPermissionsView> {
  final RBACRepository _repository = RBACRepository();
  List<Role> _roles = [];
  Map<String, List<Permission>> _permissionsByModule = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getRoles(),
        _repository.getPermissions(),
      ]);
      setState(() {
        _roles = results[0] as List<Role>;
        _permissionsByModule = results[1] as Map<String, List<Permission>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalPermissions {
    int count = 0;
    _permissionsByModule.forEach((_, perms) => count += perms.length);
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          PageHeader(
            title: 'Roles & Permissions',
            subtitle: 'Define admin roles and assign granular permissions for platform access control.',
            actionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showCreateRoleDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats Row
          Row(
            children: [
              _buildStatCard('Total Roles', _roles.length.toString(), Icons.admin_panel_settings_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 16),
              _buildStatCard('Active Roles', _roles.where((r) => r.isActive).length.toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildStatCard('System Roles', _roles.where((r) => r.isSystemRole).length.toString(), Icons.lock_outline, const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildStatCard('Permissions', _totalPermissions.toString(), Icons.vpn_key_outlined, const Color(0xFF8B5CF6)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Two-Column Layout: Roles + Permissions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roles Table (left side, takes 60%)
              Expanded(
                flex: 6,
                child: AdvancedCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Color(0xFF3B82F6), size: 20),
                            const SizedBox(width: 10),
                            Text('Roles', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Text('${_roles.length} roles', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                      else
                        AdvancedTable(
                          columns: const ['Role Name', 'Category', 'Permissions', 'Users', 'Status', 'Actions'],
                          rows: _roles.map((role) {
                            return [
                              // Role Name
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(role.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                      if (role.isSystemRole) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.lock, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                                      ],
                                    ],
                                  ),
                                  if (role.description != null)
                                    Text(role.description!, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                              // Category
                              StatusBadge(status: role.category),
                              // Permission Count
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${role.permissionCount}',
                                  style: GoogleFonts.inter(color: const Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              // User Count
                              Text('${role.userCount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              // Status
                              StatusBadge(status: role.isActive ? 'active' : 'inactive'),
                              // Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _actionIconButton(Icons.edit_outlined, const Color(0xFF3B82F6), 'Edit', () => _showEditRoleDialog(role)),
                                  if (!role.isSystemRole)
                                    _actionIconButton(Icons.delete_outline, const Color(0xFFEF4444), 'Delete', () => _confirmDeleteRole(role)),
                                  _actionIconButton(Icons.visibility_outlined, Colors.white54, 'View', () => _showRoleDetailDialog(role)),
                                ],
                              ),
                            ];
                          }).toList(),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
              ),

              const SizedBox(width: 20),

              // Permissions Panel (right side, takes 40%)
              Expanded(
                flex: 4,
                child: AdvancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vpn_key, color: Color(0xFF8B5CF6), size: 20),
                          const SizedBox(width: 10),
                          Text('Permissions by Module', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_permissionsByModule.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.vpn_key_outlined, size: 40, color: Colors.white.withValues(alpha: 0.2)),
                                const SizedBox(height: 12),
                                Text('No permissions defined', style: GoogleFonts.inter(color: Colors.white54)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._permissionsByModule.entries.map((entry) {
                          return _buildPermissionModule(entry.key, entry.value);
                        }),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
        onPressed: _loadData,
        tooltip: 'Refresh',
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIconButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildPermissionModule(String module, List<Permission> permissions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  module.toUpperCase(),
                  style: GoogleFonts.inter(color: const Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Text('${permissions.length} permissions', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: permissions.map((p) {
              Color actionColor;
              switch (p.action) {
                case 'create': actionColor = const Color(0xFF22C55E); break;
                case 'delete': actionColor = const Color(0xFFEF4444); break;
                case 'view': actionColor = const Color(0xFF3B82F6); break;
                default: actionColor = const Color(0xFFF59E0B);
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: actionColor.withValues(alpha: 0.2)),
                ),
                child: Text(p.action, style: GoogleFonts.inter(color: actionColor, fontSize: 11, fontWeight: FontWeight.w500)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'system';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Create New Role', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Role Name *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Description'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Category'),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'powerfill_staff', child: Text('PowerFill Staff')),
                      DropdownMenuItem(value: 'vendor_staff', child: Text('Vendor Staff')),
                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    ],
                    onChanged: (v) => setState(() => category = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameController.text.isEmpty) return;
                        setState(() => isSubmitting = true);
                        final success = await _repository.createRole(
                          name: nameController.text,
                          description: descController.text.isNotEmpty ? descController.text : null,
                          category: category,
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Role created successfully!'), backgroundColor: Colors.green),
                          );
                          _loadData();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRoleDialog(Role role) {
    final nameController = TextEditingController(text: role.name);
    final descController = TextEditingController(text: role.description ?? '');
    bool isActive = role.isActive;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Role: ${role.name}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Role Name'),
                    enabled: !role.isSystemRole,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Description'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Active', style: GoogleFonts.inter(color: Colors.white)),
                    subtitle: Text(isActive ? 'Role is active' : 'Role is disabled', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    value: isActive,
                    activeColor: const Color(0xFF22C55E),
                    onChanged: (v) => setState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (role.isSystemRole)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('System role name cannot be changed', style: GoogleFonts.inter(color: const Color(0xFFF59E0B), fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        final success = await _repository.updateRole(
                          role.id,
                          name: nameController.text != role.name ? nameController.text : null,
                          description: descController.text,
                          isActive: isActive,
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Role updated successfully!'), backgroundColor: Colors.green),
                          );
                          _loadData();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteRole(Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Role', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Are you sure you want to delete "${role.name}"?\nThis action cannot be undone.',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              if (role.userCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 8),
                      Text('${role.userCount} user(s) are assigned to this role', style: GoogleFonts.inter(color: const Color(0xFFF59E0B), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _repository.deleteRole(role.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Role "${role.name}" deleted'), backgroundColor: Colors.green),
                );
                _loadData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete role. Users may still be assigned.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRoleDetailDialog(Role role) async {
    final detail = await _repository.getRoleDetail(role.id);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  if (role.description != null)
                    Text(role.description!, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Category', role.category.toUpperCase()),
              _detailRow('Level', role.level.toString()),
              _detailRow('System Role', role.isSystemRole ? 'Yes' : 'No'),
              _detailRow('Status', role.isActive ? 'Active' : 'Inactive'),
              _detailRow('Users Assigned', role.userCount.toString()),
              const Divider(color: Colors.white12, height: 24),
              Text('Permissions', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (detail != null && detail.permissions != null && detail.permissions!.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: detail.permissions!.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                      ),
                      child: Text(p.slug, style: GoogleFonts.inter(color: const Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                )
              else
                Text('No permissions assigned', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}
