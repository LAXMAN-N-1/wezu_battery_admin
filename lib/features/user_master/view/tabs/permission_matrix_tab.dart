import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/role.dart';
import '../../data/providers/user_master_providers.dart';
import '../../../../../core/widgets/admin_ui_components.dart';

class PermissionMatrixTab extends ConsumerStatefulWidget {
  const PermissionMatrixTab({super.key});

  @override
  ConsumerState<PermissionMatrixTab> createState() => _PermissionMatrixTabState();
}

class _PermissionMatrixTabState extends ConsumerState<PermissionMatrixTab> {
  // Local state for interactive toggles: { module: { roleName: accessLevel (0/1/2) } }
  final Map<String, Map<String, int>> matrix = {};
  bool _initialized = false;

  /// Convert snake_case DB role name to Display Name
  String _displayRoleName(String dbName) {
    return dbName
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  void _initializeMatrix(List<Role> roles, List<Map<String, dynamic>> modules) {
    if (_initialized) return;
    
    for (var mRecord in modules) {
      final m = mRecord['label'] as String? ?? mRecord['module'] as String? ?? 'Other';
      matrix[m] = {};
      
      for (var role in roles) {
        // Find if this role has any permissions in this module
        final level = role.permissions.modules[mRecord['module']] ?? PermissionLevel.noAccess;
        
        if (level == PermissionLevel.full) {
          matrix[m]![role.name] = 2; // Full
        } else if (level == PermissionLevel.view) {
          matrix[m]![role.name] = 1; // Read
        } else {
          matrix[m]![role.name] = 0; // None
        }
      }
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final modulesAsync = ref.watch(permissionModulesProvider);

    return rolesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading roles: $err', style: const TextStyle(color: Color(0xFFEF4444)))),
      data: (roles) {
        return modulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading modules: $err', style: const TextStyle(color: Color(0xFFEF4444)))),
          data: (modules) {
            // Use up to 6 roles for display (to fit the screen)
            final displayRoles = roles.length > 6 ? roles.sublist(0, 6) : roles;
            
            _initializeMatrix(displayRoles, modules);
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AdvancedCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('System Permission Matrix', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  'Click on cells to toggle: None (Gray) → Read-Only (Blue) → Full Control (Green). Showing ${displayRoles.length} of ${roles.length} roles.',
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Show loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Row(children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 12), Text('Saving Matrix...')])),
                              );
                              
                              try {
                                for (var role in displayRoles) {
                                  final List<String> roleSlugs = [];
                                  
                                  for (var mRecord in modules) {
                                    final moduleLabel = mRecord['label'] as String? ?? mRecord['module'] as String? ?? 'Other';
                                    final state = matrix[moduleLabel]?[role.name] ?? 0;
                                    
                                    if (state == 0) continue; // No access
                                    
                                    final perms = (mRecord['permissions'] as List? ?? []);
                                    
                                    if (state == 2) {
                                      // FULL Access: Add all slugs in this module
                                      for (var p in perms) {
                                        if (p is Map && p.containsKey('id')) {
                                          roleSlugs.add(p['id'] as String);
                                        }
                                      }
                                    } else if (state == 1) {
                                      // READ Access: Add only 'view' or 'list' slugs
                                      for (var p in perms) {
                                        if (p is Map && p.containsKey('id')) {
                                          final slug = p['id'] as String;
                                          final action = (p['action'] as String? ?? '').toLowerCase();
                                          if (action.contains('view') || action.contains('read') || action.contains('list')) {
                                            roleSlugs.add(slug);
                                          }
                                        }
                                      }
                                    }
                                  }
                                  
                                  // Update role via repository
                                  await ref.read(userMasterRepositoryProvider).updateRolePermissions(int.parse(role.id), roleSlugs);
                                }
                                
                                // Done!
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Permissions Matrix saved successfully!'), backgroundColor: Color(0xFF22C55E)),
                                  );
                                  // Refetch roles to update UI
                                  ref.invalidate(rolesProvider);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save matrix: $e'), backgroundColor: const Color(0xFFEF4444)),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save, size: 18, color: Colors.white),
                            label: const Text('Save Matrix', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          _legendItem(Colors.grey, 'NONE'),
                          const SizedBox(width: 20),
                          _legendItem(const Color(0xFF3B82F6), 'READ'),
                          const SizedBox(width: 20),
                          _legendItem(const Color(0xFF22C55E), 'FULL'),
                        ],
                      ),
                    ),
                    // Build custom matrix grid instead of DataTable for consistency
                    _buildMatrixGrid(displayRoles, modules),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatrixGrid(List<Role> displayRoles, List<Map<String, dynamic>> modules) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: Text('MODULES / FEATURES', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
                ...displayRoles.map((r) => SizedBox(
                  width: 100,
                  child: Text(
                    _displayRoleName(r.name).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Data rows
          ...modules.asMap().entries.map((entry) {
            final idx = entry.key;
            final mRecord = entry.value;
            final moduleLabel = mRecord['label'] as String? ?? mRecord['module'] as String? ?? 'Other';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: idx < modules.length - 1
                    ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        const Icon(Icons.extension_outlined, size: 16, color: Colors.white38),
                        const SizedBox(width: 8),
                        Flexible(child: Text(moduleLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  ...displayRoles.map((role) {
                    final state = matrix[moduleLabel]?[role.name] ?? 0;
                    return SizedBox(
                      width: 100,
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              matrix[moduleLabel]![role.name] = (state + 1) % 3;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 80,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _getColor(state).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _getColor(state).withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getLabel(state),
                              style: TextStyle(color: _getColor(state), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ).animate(delay: (idx * 30).ms).fadeIn(duration: 300.ms).slideX(begin: 0.03);
          }),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getColor(int state) {
    if (state == 0) return Colors.grey;
    if (state == 1) return const Color(0xFF3B82F6);
    return const Color(0xFF22C55E);
  }

  String _getLabel(int state) {
    if (state == 0) return 'NONE';
    if (state == 1) return 'READ';
    return 'FULL';
  }
}
