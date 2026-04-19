import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            const SizedBox(height: 24),
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by User ID, IP, or Action...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white54),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 24),
            _buildLogTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTable() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const ['Timestamp', 'User', 'Role', 'Action Type', 'Target Module', 'IP Address', 'Status'],
        rows: List.generate(10, (index) {
          final isSuccess = index != 3 && index != 7;
          return [
            Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().subtract(Duration(hours: index * 2))), style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text('Laxman (USR-001)', style: const TextStyle(color: Colors.white)),
            Text('Super Admin', style: const TextStyle(color: Colors.white70)),
            Text(isSuccess ? 'Login' : 'Failed Login Attempt', style: TextStyle(color: isSuccess ? Colors.white : const Color(0xFFEF4444))),
            Text('Auth Service', style: const TextStyle(color: Colors.white54)),
            Text('192.168.1.${100 + index}', style: const TextStyle(fontFamily: 'monospace', color: Colors.white54)),
            StatusBadge(status: isSuccess ? 'Completed' : 'Failed'),
          ];
        }),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }
}
