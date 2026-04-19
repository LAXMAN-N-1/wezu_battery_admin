import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/role.dart';
import '../data/repositories/role_repository.dart';
import '../../../core/widgets/admin_ui_components.dart';

class RolesPermissionsView extends StatefulWidget {
  const RolesPermissionsView({super.key});

  @override
  State<RolesPermissionsView> createState() => _RolesPermissionsViewState();
}

class _RolesPermissionsViewState extends State<RolesPermissionsView>
    with SingleTickerProviderStateMixin {
  final RoleRepository _repository = RoleRepository();
  List<Role> _roles = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final roles = await _repository.getRoles();
    // Permissions are accessed via repository methods in the permission matrix tab
    await _repository.getPermissions();
    setState(() {
      _roles = roles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: PageHeader(
            title: 'Roles & Permissions',
            subtitle: 'Manage system roles and their access levels',
            actionButton: ElevatedButton.icon(
              onPressed: () => _showCreateRoleDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Create Role',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
        const SizedBox(height: 16),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Roles'),
              Tab(text: 'Permission Matrix'),
              Tab(text: 'Audit Log'),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 16),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRolesTab(),
                    _buildPermissionMatrixTab(),
                    _buildAuditLogTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRolesTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final role = _roles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AdvancedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _roleColor(role.name).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: _roleColor(role.name),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              role.name,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (role.isSystem) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'SYSTEM',
                                  style: TextStyle(
                                    color: const Color(0xFF3B82F6),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          role.description,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${role.permissions.length} permissions',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: role.isActive,
                    onChanged: (v) async {
                      await _repository.updateRole(role.copyWith(isActive: v));
                      _loadData();
                    },
                    activeThumbColor: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditRoleDialog(role),
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    role.permissions.take(8).map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Text(
                          p is Map ? p['name'] : p.toString(),
                          style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 10),
                        ),
                      );
                    }).toList()..addAll(
                      role.permissions.length > 8
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  '+${role.permissions.length - 8} more',
                                  style: TextStyle(
                                    color: const Color(0xFF3B82F6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]
                          : [],
                    ),
              ),
            ],
          ),
        ),
        ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildPermissionMatrixTab() {
    final categories = _repository.getPermissionCategories();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final idx = entry.key;
          final category = entry.value;
          final perms = _repository.getPermissionsByCategory(category);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AdvancedCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    category,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
                // Custom grid matching AdvancedTable style
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 180,
                              child: Text('PERMISSION', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                            ..._roles.map((r) => SizedBox(
                              width: 90,
                              child: Text(
                                r.name,
                                style: TextStyle(color: _roleColor(r.name), fontSize: 11, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            )),
                          ],
                        ),
                      ),
                      // Rows
                      ...perms.asMap().entries.map((permEntry) {
                        final perm = permEntry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: permEntry.key < perms.length - 1
                                ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)))
                                : null,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(perm.name, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                    Text(perm.description, style: TextStyle(color: Colors.white38, fontSize: 10), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              ..._roles.map((role) {
                                bool hasPermission = false;
                                for (var p in role.permissions) {
                                  if (p is int && p == perm.id) hasPermission = true;
                                  if (p is Map && p['id'] == perm.id) hasPermission = true;
                                }
                                return SizedBox(
                                  width: 90,
                                  child: Center(
                                    child: Checkbox(
                                      value: hasPermission,
                                      onChanged: (v) async {
                                        await _repository.togglePermission(role, perm.id);
                                        _loadData();
                                      },
                                      activeColor: const Color(0xFF22C55E),
                                      side: const BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ).animate(delay: (idx * 80).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05);
        }).toList(),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    final auditEntries = [
      {
        'admin': 'Murari Varma',
        'action': 'Removed finance.manage from Supervisor',
        'time': '8 hours ago',
        'icon': Icons.remove_circle_outline,
        'color': const Color(0xFFEF4444),
      },
      {
        'admin': 'Murari Varma',
        'action': 'Added kyc.approve to Support role',
        'time': '2 days ago',
        'icon': Icons.add_circle_outline,
        'color': const Color(0xFF22C55E),
      },
      {
        'admin': 'System',
        'action': 'Created custom role "Auditor"',
        'time': '5 days ago',
        'icon': Icons.add,
        'color': const Color(0xFF3B82F6),
      },
      {
        'admin': 'Deepak Verma',
        'action': 'Toggled users.suspend for Supervisor role',
        'time': '1 week ago',
        'icon': Icons.swap_horiz,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: auditEntries.length,
      itemBuilder: (context, index) {
        final entry = auditEntries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AdvancedCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (entry['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  entry['icon'] as IconData,
                  color: entry['color'] as Color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['action'] as String,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      'by ${entry['admin']}',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                entry['time'] as String,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05);
      },
    );
  }

  void _showCreateRoleDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Custom Role',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Role Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) return;
                        await _repository.createRole(
                          name: nameController.text,
                          description: descController.text,
                          permissionIds: [],
                        );
                        _loadData();
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditRoleDialog(Role role) {
    final nameController = TextEditingController(text: role.name);
    final descController = TextEditingController(text: role.description);
    bool isActive = role.isActive;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Role: ${role.name}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: Text('Active', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) return;
                          await _repository.updateRole(
                            role.copyWith(
                              name: nameController.text,
                              description: descController.text,
                              isActive: isActive,
                            ),
                          );
                          if (!context.mounted || !mounted) return;
                          _loadData();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(String name) {
    switch (name.toLowerCase()) {
      case 'admin':
        return const Color(0xFF8B5CF6);
      case 'supervisor':
        return const Color(0xFF6366F1);
      case 'support':
        return const Color(0xFF14B8A6);
      case 'dealer':
        return const Color(0xFFF59E0B);
      case 'customer':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
