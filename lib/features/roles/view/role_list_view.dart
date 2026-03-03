import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/models/role_model.dart';
import 'role_form_dialog.dart';

class RoleListView extends ConsumerWidget {
  const RoleListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              Text(
                'Roles & Permissions',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newRole = await showDialog<RoleModel>(
                    context: context,
                    builder: (context) => const RoleFormDialog(),
                  );
                  if (newRole != null) {
                    ref.read(roleProvider.notifier).addRole(newRole);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          SearchFilterBar(
            onSearch: (value) => ref.read(roleProvider.notifier).setSearchQuery(value),
            onFilterTap: () {}, // No filters for roles yet
            // activeFilters: [],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: AdminDataTable(
                  columns: const [
                    DataColumn(label: Text('Role Name')),
                    DataColumn(label: Text('Users')),
                    DataColumn(label: Text('Permissions')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: state.roles.map((role) {
                    return DataRow(cells: [
                      DataCell(Text(role.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(role.userCount.toString())),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: role.permissions.take(3).map((p) => 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(p, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              )
                            ).toList()..addAll(role.permissions.length > 3 ? [
                              Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: Text('+${role.permissions.length - 3}', style: const TextStyle(fontSize: 10, color: Colors.white38)), 
                              )
                            ] : []),
                          ),
                        ),
                      ),
                      DataCell(Text(role.description, style: const TextStyle(color: Colors.white54))),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () {},
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
