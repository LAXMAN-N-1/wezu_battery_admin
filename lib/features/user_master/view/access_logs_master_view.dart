import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/admin_ui_components.dart';
import '../data/models/access_log.dart';
import '../data/providers/user_master_providers.dart';

class AccessLogsMasterView extends ConsumerStatefulWidget {
  const AccessLogsMasterView({super.key});

  @override
  ConsumerState<AccessLogsMasterView> createState() => _AccessLogsMasterViewState();
}

class _AccessLogsMasterViewState extends ConsumerState<AccessLogsMasterView> {
  static const String _queryKey = 'skip=0&limit=100';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(accessLogsProviderByKey(_queryKey));

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Access Logs & Audit Trail',
              subtitle: 'Monitor system logins, permission changes, and security events.',
              actionButton: OutlinedButton.icon(
                onPressed: () => ref.invalidate(accessLogsProviderByKey(_queryKey)),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text('Refresh', style: TextStyle(color: Colors.white)),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            const SizedBox(height: 24),
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, IP, or status...',
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
                  child: logsAsync.when(
                    data: (logs) => Text(
                      '${_filterLogs(logs).length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) =>
                        const Icon(Icons.error_outline, color: Colors.redAccent),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 24),
            logsAsync.when(
              data: (logs) => _buildLogTable(_filterLogs(logs)),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Failed to load audit logs: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  List<AccessLog> _filterLogs(List<AccessLog> logs) {
    if (_searchQuery.isEmpty) return logs;
    return logs.where((log) {
      final haystack = [
        log.userId,
        log.userName,
        log.email,
        log.roleName,
        log.status,
        log.ipAddress,
        log.deviceBrowser ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();
  }

  Widget _buildLogTable(List<AccessLog> logs) {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const ['Timestamp', 'Account', 'Role', 'Status', 'IP Address', 'Device / Browser'],
        rows: logs.map((log) {
          return [
            Text(
              DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp.toLocal()),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.userName.isNotEmpty ? log.userName : 'User #${log.userId}',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  log.email.isNotEmpty ? log.email : 'ID: ${log.userId}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              log.roleName.isNotEmpty ? log.roleName : 'Unknown',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
            StatusBadge(status: log.isSuccess ? 'Success' : 'Failed'),
            Text(
              log.ipAddress.isNotEmpty ? log.ipAddress : '--',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              (log.deviceBrowser ?? '--').replaceAll('\n', ' '),
              style: const TextStyle(color: Colors.white54),
              overflow: TextOverflow.ellipsis,
            ),
          ];
        }).toList(),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05);
  }
}
