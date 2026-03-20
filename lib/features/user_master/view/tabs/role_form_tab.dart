import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleFormTab extends StatefulWidget {
  final VoidCallback onCancel;

  const RoleFormTab({super.key, required this.onCancel});

  @override
  State<RoleFormTab> createState() => _RoleFormTabState();
}

class _RoleFormTabState extends State<RoleFormTab> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  Map<String, String> permissions = {
    'Dashboard': 'View Only',
    'User Management': 'No Access',
    'Fleet & Inventory': 'No Access',
    'Stations': 'No Access',
    'Finance': 'No Access',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
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
                    ElevatedButton(
                      onPressed: widget.onCancel, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Save Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      const SizedBox(height: 20),
                      const Text('Description', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('What does this role do?'),
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
                                      Text(module, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: permissions[module],
                                          dropdownColor: const Color(0xFF1E293B),
                                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 13),
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
