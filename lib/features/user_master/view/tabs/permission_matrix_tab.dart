import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/role.dart';
import '../../data/providers/user_master_providers.dart';

class PermissionMatrixTab extends ConsumerStatefulWidget {
  const PermissionMatrixTab({super.key});

  @override
  ConsumerState<PermissionMatrixTab> createState() => _PermissionMatrixTabState();
}

class _PermissionMatrixTabState extends ConsumerState<PermissionMatrixTab> {
  // Local state for interactive toggles: { module: { roleName: accessLevel (0/1/2) } }
  final Map<String, Map<String, int>> matrix = {};
  String? _lastInitKey;

  /// Convert snake_case DB role name to Display Name
  String _displayRoleName(String dbName) {
    return dbName
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  void _initializeMatrix(List<Role> roles, List<Map<String, dynamic>> modules) {
    final initKey =
        '${roles.map((r) => r.id).join(',')}|${modules.map((m) => (m['module'] ?? m['label']).toString()).join(',')}';
    if (_lastInitKey == initKey) return;
    _lastInitKey = initKey;

    matrix.clear();
    for (var mRecord in modules) {
      final m = mRecord['label'] as String? ?? mRecord['module'] as String? ?? 'Other';
      matrix[m] = {};
      
      for (var role in roles) {
        // Find if this role has any permissions in this module
        final moduleKey = (mRecord['module'] ?? '').toString();
        final labelKey = (mRecord['label'] ?? '').toString();
        final level =
            role.permissions.modules[moduleKey] ??
            role.permissions.modules[labelKey] ??
            PermissionLevel.noAccess;
        
        if (level == PermissionLevel.full) {
          matrix[m]![role.name] = 2; // Full
        } else if (level == PermissionLevel.view) {
          matrix[m]![role.name] = 1; // Read
        } else {
          matrix[m]![role.name] = 0; // None
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final modulesAsync = ref.watch(permissionModulesProvider);

    return rolesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading roles: $err', style: const TextStyle(color: Colors.red))),
      data: (roles) {
        return modulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading modules: $err', style: const TextStyle(color: Colors.red))),
          data: (modules) {
            final displayRoles = roles;
            
            _initializeMatrix(displayRoles, modules);
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
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
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Show loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Row(children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 12), Text('Saving Matrix...')])),
                              );
                              
                              try {
                                int updatedRoles = 0;
                                for (var role in displayRoles) {
                                  final roleId = int.tryParse(role.id);
                                  if (roleId == null) continue;

                                  final List<String> roleSlugs = [];
                                  
                                  for (var mRecord in modules) {
                                    final moduleLabel = mRecord['label'] as String? ?? mRecord['module'] as String? ?? 'Other';
                                    final state = matrix[moduleLabel]?[role.name] ?? 0;
                                    
                                    if (state == 0) continue; // No access
                                    
                                    final perms = (mRecord['permissions'] as List? ?? []);
                                    
                                    if (state == 2) {
                                      // FULL Access: Add all slugs in this module
                                      for (var p in perms) {
                                        if (p is Map) {
                                          final slug = (p['id'] ?? p['slug'])?.toString();
                                          if (slug != null && slug.isNotEmpty) {
                                            roleSlugs.add(slug);
                                          }
                                        }
                                      }
                                    } else if (state == 1) {
                                      // READ Access: Add only 'view' or 'list' slugs
                                      for (var p in perms) {
                                        if (p is Map) {
                                          final slug = (p['id'] ?? p['slug'])?.toString();
                                          if (slug == null || slug.isEmpty) continue;
                                          final action = (p['action'] ?? p['label'] ?? '').toString().toLowerCase();
                                          if (action.contains('view') || action.contains('read') || action.contains('list')) {
                                            roleSlugs.add(slug);
                                          }
                                        }
                                      }
                                    }
                                  }
                                  
                                  // Update role via repository
                                  await ref
                                      .read(userMasterRepositoryProvider)
                                      .updateRolePermissions(roleId, roleSlugs);
                                  updatedRoles += 1;
                                }
                                
                                // Done!
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        updatedRoles > 0
                                            ? 'Permissions Matrix saved successfully!'
                                            : 'No editable roles were saved.',
                                      ),
                                      backgroundColor: updatedRoles > 0
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  );
                                  // Refetch roles to update UI
                                  ref.invalidate(rolesProvider);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save matrix: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save, size: 18, color: Colors.white),
                            label: const Text('Save Matrix', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          _legendItem(Colors.grey, 'NONE'),
                          const SizedBox(width: 20),
                          _legendItem(Colors.blue, 'READ'),
                          const SizedBox(width: 20),
                          _legendItem(Colors.green, 'FULL'),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: DataTableThemeData(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                            dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.hovered)) return Colors.white.withValues(alpha: 0.02);
                              return null;
                            }),
                          ),
                        ),
                        child: DataTable(
                          columnSpacing: 24,
                          headingTextStyle: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                          dataTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          columns: [
                            const DataColumn(label: SizedBox(width: 160, child: Text('Modules / Features'))),
                            ...displayRoles.map((r) => DataColumn(
                              label: SizedBox(
                                width: 90,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _displayRoleName(r.name),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],
                          rows: modules.map((mRecord) {
                            final moduleLabel = mRecord['label'] as String? ?? mRecord['module'] as String? ?? 'Other';
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 160,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.extension_outlined, size: 16, color: Colors.white38),
                                        const SizedBox(width: 8),
                                        Flexible(child: Text(moduleLabel, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                ),
                                ...displayRoles.map((role) {
                                  final state = matrix[moduleLabel]?[role.name] ?? 0;
                                  return DataCell(
                                    Center(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            matrix[moduleLabel]![role.name] = (state + 1) % 3;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 80,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: _getColor(state).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
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
                            );
                          }).toList(),
                        ),
                      ),
                    ),
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
    if (state == 1) return Colors.blue;
    return Colors.green;
  }

  String _getLabel(int state) {
    if (state == 0) return 'NONE';
    if (state == 1) return 'READ';
    return 'FULL';
  }
}
