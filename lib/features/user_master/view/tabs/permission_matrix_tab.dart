import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PermissionMatrixTab extends StatefulWidget {
  const PermissionMatrixTab({super.key});

  @override
  State<PermissionMatrixTab> createState() => _PermissionMatrixTabState();
}

class _PermissionMatrixTabState extends State<PermissionMatrixTab> {
  final List<String> modules = [
    'Dashboard', 'User Management', 'Roles & Permissions', 'Fleet Management', 'Inventory Audits',
    'Stations Manager', 'Dealer Config', 'Finance Reports', 'Logistics Map', 'IoT Telematics', 'CMS Editor'
  ];

  final List<String> roles = ['Super Admin', 'Admin', 'Manager', 'Dealer', 'Support Agent'];

  // Temporary local state for the interactive toggles
  final Map<String, Map<String, int>> matrix = {};

  @override
  void initState() {
    super.initState();
    // 0 = No, 1 = Read, 2 = Write/Full
    for (var m in modules) {
      matrix[m] = {};
      for (var r in roles) {
        if (r == 'Super Admin') {
          matrix[m]![r] = 2;
        } else if (r == 'Admin') {
          matrix[m]![r] = m == 'Settings' ? 1 : 2;
        } else if (r == 'Reader') {
          matrix[m]![r] = 1; 
        } else {
          matrix[m]![r] = 0; // default NO
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text('Click on cells to toggle access: None (Gray) -> Read-Only (Blue) -> Full Control (Green).', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission Matrix saved!'), backgroundColor: Colors.green));
                    },
                    icon: const Icon(Icons.save, size: 18, color: Colors.white),
                    label: const Text('Save Matrix', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
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
                  columnSpacing: 40,
                  headingTextStyle: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                  dataTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  columns: [
                    const DataColumn(label: Text('Modules / Features')),
                    ...roles.map((r) => DataColumn(label: Text(r))),
                  ],
                  rows: modules.map((module) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              const Icon(Icons.extension_outlined, size: 16, color: Colors.white38),
                              const SizedBox(width: 8),
                              Text(module, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        ...roles.map((role) {
                          final state = matrix[module]![role]!;
                          return DataCell(
                            Center(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    matrix[module]![role] = (state + 1) % 3;
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
