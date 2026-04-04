import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/providers/user_master_providers.dart';

class RoleFormTab extends ConsumerStatefulWidget {
  final VoidCallback onCancel;

  const RoleFormTab({super.key, required this.onCancel});

  @override
  ConsumerState<RoleFormTab> createState() => _RoleFormTabState();
}

class _RoleFormTabState extends ConsumerState<RoleFormTab> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  // Module permissions: module name -> access level string
  Map<String, String> permissions = {
    'Dashboard': 'View Only',
    'User Management': 'No Access',
    'Fleet & Inventory': 'No Access',
    'Stations': 'No Access',
    'Dealers': 'No Access',
    'Finance': 'No Access',
    'Rentals & Orders': 'No Access',
    'IoT & Telematics': 'No Access',
    'Reports & Analytics': 'No Access',
    'System Settings': 'No Access',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role name is required'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(userMasterRepositoryProvider);

      // Convert display name to snake_case for DB
      final dbName = name.toLowerCase().replaceAll(' ', '_');

      await repo.createRole({
        'name': dbName,
        'description': _descController.text.trim(),
        'category': 'system',
        'level': 0,
        'is_system_role': false,
        'is_active': true,
        'permissions': [], // Will be assigned separately via permission matrix
      });

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role "$name" created successfully!'), backgroundColor: Colors.green),
        );
        // Refresh roles list
        ref.invalidate(rolesProvider);
        // Clear form
        _nameController.clear();
        _descController.clear();
        setState(() {
          permissions.updateAll((key, value) => 'No Access');
        });
        // Switch back to roles list
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Custom Role', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Row(
                  children: [
                    TextButton(onPressed: widget.onCancel, child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRole,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                      label: Text(_isSaving ? 'Saving...' : 'Save Role', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Role Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Define the basic information for this custom role.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 24),
                      const Text('Role Name *', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('e.g. Regional Support Agent'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DB name: ${_nameController.text.trim().toLowerCase().replaceAll(' ', '_')}',
                        style: const TextStyle(color: Colors.white24, fontSize: 11, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 20),
                      const Text('Description', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('What does this role do?'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Permissions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Set initial broad access levels. You can fine-tune later in the Permission Matrix.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: permissions.keys.map((module) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getModuleIcon(module),
                                            size: 18,
                                            color: _getAccessColor(permissions[module]!),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(module, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: permissions[module],
                                          dropdownColor: const Color(0xFF1E293B),
                                          style: TextStyle(
                                            color: _getAccessColor(permissions[module]!),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          items: ['Full Access', 'View Only', 'Limited', 'No Access'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (val) {
                                            setState(() => permissions[module] = val!);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (module != permissions.keys.last) const Divider(color: Colors.white10, height: 1),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccessColor(String access) {
    switch (access) {
      case 'Full Access': return Colors.greenAccent;
      case 'View Only': return Colors.blueAccent;
      case 'Limited': return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }

  IconData _getModuleIcon(String module) {
    switch (module) {
      case 'Dashboard': return Icons.dashboard_outlined;
      case 'User Management': return Icons.people_outline;
      case 'Fleet & Inventory': return Icons.inventory_2_outlined;
      case 'Stations': return Icons.location_on_outlined;
      case 'Dealers': return Icons.storefront_outlined;
      case 'Finance': return Icons.attach_money;
      case 'Rentals & Orders': return Icons.receipt_long_outlined;
      case 'IoT & Telematics': return Icons.sensors_outlined;
      case 'Reports & Analytics': return Icons.analytics_outlined;
      case 'System Settings': return Icons.settings_outlined;
      default: return Icons.extension_outlined;
    }
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
    );
  }
}
