import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/admin_ui_components.dart';
import '../data/providers/admin_group_provider.dart';
import '../data/models/admin_group_model.dart';

class AdminGroupsMasterView extends ConsumerStatefulWidget {
  const AdminGroupsMasterView({super.key});

  @override
  ConsumerState<AdminGroupsMasterView> createState() => _AdminGroupsMasterViewState();
}

class _AdminGroupsMasterViewState extends ConsumerState<AdminGroupsMasterView> {
  void _showCreateGroupDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Create Admin Group', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Active', style: TextStyle(color: Colors.white)),
                        
                        Switch(
                          value: isActive,
                          onChanged: (val) {
                            setState(() {
                              isActive = val;
                            });
                          },
                          activeThumbColor: Colors.blueAccent,
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    try {
                      final repo = ref.read(adminGroupRepositoryProvider);
                      await repo.createGroup({
                        'name': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'is_active': isActive,
                      });
                      ref.invalidate(adminGroupsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  child: const Text('Create', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(adminGroupsProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Admin Groups',
              subtitle: 'Organize users by regional or business-unit groups for streamlined access provisioning.',
              actionButton: ElevatedButton.icon(
                onPressed: _showCreateGroupDialog,
                icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                label: const Text('Create Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No admin groups found. Create one to get started.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ),
                  );
                }
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: groups.map((g) => SizedBox(
                    width: 300, 
                    child: _buildGroupCard(g)
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading groups: $err', style: const TextStyle(color: Colors.redAccent))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(AdminGroupModel group) {
    final status = group.isActive ? 'Active' : 'Inactive';
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: group.isActive ? Colors.greenAccent : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(group.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(group.description ?? 'No description provided', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   const Icon(Icons.group, size: 16, color: Colors.blueAccent),
                   const SizedBox(width: 8),
                   Text('${group.memberCount} Members', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                 ],
               ),
               TextButton(
                 onPressed: () {},
                 child: const Text('Manage', style: TextStyle(color: Colors.blueAccent)),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
