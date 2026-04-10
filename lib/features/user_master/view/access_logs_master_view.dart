import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/admin_ui_components.dart';

class AccessLogsMasterView extends ConsumerStatefulWidget {
  const AccessLogsMasterView({super.key});

  @override
  ConsumerState<AccessLogsMasterView> createState() => _AccessLogsMasterViewState();
}

class _AccessLogsMasterViewState extends ConsumerState<AccessLogsMasterView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Access Logs & Audit Trail',
              subtitle: 'Monitor system logins, permission changes, and security events.',
              actionButton: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: const Text('Download CSV', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            _buildLogTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by User ID, IP, or Action...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.filter_list, color: Colors.white54),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
              columnSpacing: 32,
              headingTextStyle: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
              dataTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Action Type')),
                DataColumn(label: Text('Target Module')),
                DataColumn(label: Text('IP Address')),
                DataColumn(label: Text('Status')),
              ],
              rows: List.generate(10, (index) {
                final isSuccess = index != 3 && index != 7;
                return DataRow(
                  cells: [
                    DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().subtract(Duration(hours: index * 2))))),
                    DataCell(Text('Laxman (USR-001)')),
                    DataCell(Text('Super Admin')),
                    DataCell(Text(isSuccess ? 'Login' : 'Failed Login Attempt', style: TextStyle(color: isSuccess ? Colors.white : Colors.redAccent))),
                    DataCell(Text('Auth Service', style: const TextStyle(color: Colors.white54))),
                    DataCell(Text('192.168.1.${100+index}', style: const TextStyle(fontFamily: 'monospace', color: Colors.white54))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isSuccess ? 'SUCCESS' : 'FAILED', style: TextStyle(color: isSuccess ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }),
            )),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
