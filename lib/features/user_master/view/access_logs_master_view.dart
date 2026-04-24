import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/csv/csv_service.dart';
import '../../../../core/widgets/admin_ui_components.dart';
import '../data/models/access_log.dart';
import '../data/providers/user_master_providers.dart';

class AccessLogsMasterView extends ConsumerStatefulWidget {
  const AccessLogsMasterView({super.key});

  @override
  ConsumerState<AccessLogsMasterView> createState() => _AccessLogsMasterViewState();
}

class _AccessLogsMasterViewState extends ConsumerState<AccessLogsMasterView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _actionFilter = 'All';
  bool _onlyFailed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AccessLog> _applyFilters(List<AccessLog> logs) {
    return logs.where((log) {
      if (_onlyFailed && log.isSuccess) return false;
      if (_actionFilter != 'All' &&
          log.actionType.toLowerCase() != _actionFilter.toLowerCase()) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return log.userName.toLowerCase().contains(query) ||
          log.userId.toLowerCase().contains(query) ||
          log.moduleAffected.toLowerCase().contains(query) ||
          log.actionType.toLowerCase().contains(query) ||
          log.ipAddress.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _exportLogsCsv(List<AccessLog> logs) async {
    final rows = <List<dynamic>>[
      [
        'Timestamp',
        'User ID',
        'User Name',
        'Role',
        'Action',
        'Module',
        'IP Address',
        'Device',
        'Status',
      ],
      ...logs.map(
        (log) => [
          DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp),
          log.userId,
          log.userName,
          log.roleName,
          log.actionType,
          log.moduleAffected,
          log.ipAddress,
          log.deviceBrowser ?? '',
          log.isSuccess ? 'SUCCESS' : 'FAILED',
        ],
      ),
    ];

    await CsvService.downloadCsv(
      rows,
      'access_logs_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(
      accessLogsProvider({'skip': 0, 'limit': 500}),
    );

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
              actionButton: logsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (logs) => OutlinedButton.icon(
                  onPressed: logs.isEmpty ? null : () => _exportLogsCsv(logs),
                  icon: const Icon(Icons.download, color: Colors.white, size: 18),
                  label: const Text('Download CSV', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Error loading access logs: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (logs) => _buildLogTable(_applyFilters(logs)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTable(List<AccessLog> logs) {
    final actionOptions = <String>{
      'All',
      ...logs.map((log) => log.actionType),
    }.toList();

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
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
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
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    value: _actionFilter,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: actionOptions
                        .map(
                          (action) => DropdownMenuItem<String>(
                            value: action,
                            child: Text(action),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _actionFilter = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _onlyFailed,
                  onSelected: (value) => setState(() => _onlyFailed = value),
                  selectedColor: Colors.red.withValues(alpha: 0.2),
                  backgroundColor: const Color(0xFF0F172A),
                  label: const Text('Failed only', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No access logs found for current filters.', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
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
                rows: logs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp))),
                      DataCell(Text('${log.userName} (${log.userId})')),
                      DataCell(Text(log.roleName.isEmpty ? '—' : log.roleName)),
                      DataCell(
                        Text(
                          log.actionType,
                          style: TextStyle(color: log.isSuccess ? Colors.white : Colors.redAccent),
                        ),
                      ),
                      DataCell(
                        Text(
                          log.moduleAffected.isEmpty ? '—' : log.moduleAffected,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                      DataCell(
                        Text(
                          log.ipAddress.isEmpty ? '—' : log.ipAddress,
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white54),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: log.isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log.isSuccess ? 'SUCCESS' : 'FAILED',
                            style: TextStyle(
                              color: log.isSuccess ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
