import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../provider/audit_provider.dart';

// Mock/Data types for Role and Permission (assuming they are defined elsewhere or need to be defined)
// Let's check where Role and RoleRepository are defined.
// Based on previous files, they should be in lib/features/users/data/models/role.dart and repositories/role_repository.dart
import '../data/models/role.dart';
import '../data/repositories/role_repository.dart';

class RolesPermissionsView extends ConsumerStatefulWidget {
  const RolesPermissionsView({super.key});

  @override
  ConsumerState<RolesPermissionsView> createState() => _RolesPermissionsViewState();
}

class _RolesPermissionsViewState extends ConsumerState<RolesPermissionsView> with SingleTickerProviderStateMixin {
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
          child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Roles & Permissions', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              
              ElevatedButton.icon(
                onPressed: () => _showCreateRoleDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Create Role', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Roles'),
              Tab(text: 'Permission Matrix'),
              Tab(text: 'Audit Log'),
            ],
          ),
        ),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _roleColor(role.name).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield_outlined, color: _roleColor(role.name), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(role.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            if (role.isSystem) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('SYSTEM', style: GoogleFonts.inter(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        Text(role.description, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('${role.permissions.length} permissions', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 12),
                  Switch(
                    value: role.isActive,
                    onChanged: (v) async {
                      await _repository.updateRole(role.copyWith(isActive: v));
                      _loadData();
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditRoleDialog(role),
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: role.permissions.take(8).map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(p is Map ? p['name'] : p.toString(), style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 10)),
                  );
                }).toList()
                ..addAll(role.permissions.length > 8
                    ? [Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('+${role.permissions.length - 8} more', style: GoogleFonts.inter(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w600)),
                      )]
                    : []),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionMatrixTab() {
    final categories = _repository.getPermissionCategories();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: categories.map((category) {
          final perms = _repository.getPermissionsByCategory(category);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(category, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.03)),
                    columns: [
                      DataColumn(label: SizedBox(width: 160, child: Text('Permission', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)))),
                      ..._roles.map((r) => DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Text(r.name, style: GoogleFonts.inter(color: _roleColor(r.name), fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ),
                      )),
                    ],
                    rows: perms.map((perm) {
                      return DataRow(cells: [
                        DataCell(SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(perm.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(perm.description, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        )),
                        ..._roles.map((role) {
                          bool hasPermission = false;
                          for (var p in role.permissions) {
                            if (p is int && p == perm.id) hasPermission = true;
                            if (p is Map && p['id'] == perm.id) hasPermission = true;
                          }
                          return DataCell(
                            Center(
                              child: Checkbox(
                                value: hasPermission,
                                onChanged: (v) async {
                                  await _repository.togglePermission(role, perm.id);
                                  _loadData();
                                },
                                activeColor: Colors.green,
                                side: const BorderSide(color: Colors.white24),
                              ),
                            ),
                          );
                        }),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    final auditState = ref.watch(auditProvider);
    
    // Initial load for roles module
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auditState.logs.isEmpty && !auditState.isLoading && auditState.error == null) {
        ref.read(auditProvider.notifier).loadLogs(module: 'roles');
      }
    });

    if (auditState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (auditState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text('Error loading logs: ${auditState.error}', style: GoogleFonts.inter(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(auditProvider.notifier).loadLogs(module: 'roles'),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (auditState.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.white.withValues(alpha: 0.1), size: 64),
            const SizedBox(height: 16),
            Text('No audit logs found for roles', style: GoogleFonts.inter(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: auditState.logs.length,
      itemBuilder: (context, index) {
        final entry = auditState.logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getAuditActionColor(entry.action).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getAuditActionIcon(entry.action), color: _getAuditActionColor(entry.action), size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.details, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      'by User #${entry.userId} ${entry.ipAddress != null ? "• ${entry.ipAddress}" : ""}', 
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, HH:mm').format(entry.timestamp), 
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAuditActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create': return Colors.green;
      case 'update': return Colors.amber;
      case 'delete': return Colors.red;
      case 'permission_change': return Colors.purple;
      default: return Colors.blue;
    }
  }

  IconData _getAuditActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      case 'permission_change': return Icons.admin_panel_settings;
      default: return Icons.info_outline;
    }
  }

  void _showCreateRoleDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Custom Role', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Role Name',
                  labelStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.15)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70)),
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      await _repository.createRole(name: nameController.text, description: descController.text, permissionIds: []);
                      _loadData();
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Create', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  )),
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
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Role: ${role.name}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role Name',
                    labelStyle: GoogleFonts.inter(color: Colors.white54),
                    filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.inter(color: Colors.white54),
                    filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: Text('Active', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.15)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70)),
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) return;
                        await _repository.updateRole(
                          role.copyWith(
                            name: nameController.text,
                            description: descController.text,
                            isActive: isActive,
                          ),
                        );
                        _loadData();
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Update', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    )),
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
      case 'admin': return Colors.purple;
      case 'supervisor': return Colors.indigo;
      case 'support': return Colors.teal;
      case 'dealer': return Colors.orange;
      case 'customer': return Colors.green;
      default: return Colors.blue;
    }
  }
}
