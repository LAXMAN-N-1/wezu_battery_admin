import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/csv/csv_service.dart';
import '../../../../core/widgets/admin_ui_components.dart';
import '../data/providers/user_master_providers.dart';

class UserBulkMasterView extends ConsumerStatefulWidget {
  const UserBulkMasterView({super.key});

  @override
  ConsumerState<UserBulkMasterView> createState() => _UserBulkMasterViewState();
}

class _UserBulkMasterViewState extends ConsumerState<UserBulkMasterView> {
  bool _isExporting = false;
  bool _isImporting = false;
  String _exportScope = 'All Users';
  final List<_BulkOperationRecord> _operations = <_BulkOperationRecord>[];

  Future<void> _exportUsers() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(userMasterRepositoryProvider);
      final data = await repo.getUsers(skip: 0, limit: 2000);
      final users = (data['items'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();

      final rows = <List<dynamic>>[
        ['id', 'full_name', 'email', 'phone_number', 'role_name', 'status'],
        ...users.map((user) => [
              user['id'],
              user['full_name'] ?? '',
              user['email'] ?? '',
              user['phone_number'] ?? user['phone'] ?? '',
              user['role_name'] ?? user['role'] ?? '',
              user['status'] ?? '',
            ]),
      ];

      await CsvService.downloadCsv(
        rows,
        'users_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      );

      _addOperation(
        operation: 'Users Export (CSV)',
        details: '${users.length} records',
        status: 'Completed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${users.length} users successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addOperation(
        operation: 'Users Export (CSV)',
        details: 'Failed',
        status: 'Failed',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importUsers() async {
    setState(() => _isImporting = true);
    try {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );

      if (file == null || file.files.single.bytes == null) {
        setState(() => _isImporting = false);
        return;
      }

      final csvText = String.fromCharCodes(file.files.single.bytes!);
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvText);

      if (rows.isEmpty) {
        throw Exception('CSV is empty');
      }

      final headers = rows.first
          .map((h) => h.toString().trim().toLowerCase())
          .toList(growable: false);
      final repo = ref.read(userMasterRepositoryProvider);

      int success = 0;
      int failed = 0;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final record = <String, String>{};
        for (var c = 0; c < headers.length; c++) {
          final value = c < row.length ? row[c].toString().trim() : '';
          record[headers[c]] = value;
        }

        final fullName = record['full_name'] ?? record['name'] ?? '';
        final email = record['email'] ?? '';
        final roleName = record['role_name'] ?? record['role'] ?? '';
        final status = (record['status'] ?? 'ACTIVE').toUpperCase();

        if (fullName.isEmpty || email.isEmpty || roleName.isEmpty) {
          failed += 1;
          continue;
        }

        try {
          await repo.createUser({
            'full_name': fullName,
            'email': email,
            'phone_number': record['phone_number'] ?? record['phone'] ?? '',
            'role_name': roleName,
            'status': status,
          });
          success += 1;
        } catch (_) {
          failed += 1;
        }
      }

      ref.invalidate(usersProvider);
      ref.invalidate(usersProviderByKey);
      ref.invalidate(userSummaryProvider);

      _addOperation(
        operation: 'Users Import (CSV)',
        details: '$success success, $failed failed',
        status: failed == 0 ? 'Completed' : 'Completed w/ Errors',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import completed. Success: $success, Failed: $failed'),
            backgroundColor: failed == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      _addOperation(
        operation: 'Users Import (CSV)',
        details: 'Failed',
        status: 'Failed',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _downloadTemplate() async {
    await CsvService.downloadCsv(
      const <List<dynamic>>[
        [
          'full_name',
          'email',
          'phone_number',
          'role_name',
          'status',
        ],
        [
          'John Doe',
          'john@example.com',
          '9876543210',
          'customer',
          'ACTIVE',
        ],
      ],
      'users_import_template',
    );
  }

  void _addOperation({
    required String operation,
    required String details,
    required String status,
  }) {
    setState(() {
      _operations.insert(
        0,
        _BulkOperationRecord(
          timestamp: DateTime.now(),
          operation: operation,
          details: details,
          status: status,
        ),
      );
    });
  }

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
              title: 'Bulk Import & Export',
              subtitle: 'Mass manage user profiles, roles, and assignments via CSV sheets.',
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImportCard()),
                const SizedBox(width: 24),
                Expanded(child: _buildExportCard()),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Operations',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentOpsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            'Import Users',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a CSV file to add or update multiple users at once.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importUsers,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined, color: Colors.white),
              label: Text(
                _isImporting ? 'Importing...' : 'Upload CSV and Import',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download, size: 16, color: Colors.white70),
            label: const Text('Download CSV Template', style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    final options = const ['All Users', 'Filtered Users', 'Roles & Permissions'];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_for_offline, size: 40, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Export Users',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Download your user database in CSV format.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ...options.map((option) {
            final selected = _exportScope == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _exportScope = option),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.green.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? Colors.green : Colors.white54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportUsers,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download, color: Colors.white, size: 18),
              label: Text(
                _isExporting ? 'Exporting...' : 'Generate Export',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOpsTable() {
    final rows = _operations.isEmpty
        ? <_BulkOperationRecord>[
            _BulkOperationRecord(
              timestamp: DateTime.now(),
              operation: 'No operations yet',
              details: 'Run an import or export to see activity.',
              status: '—',
            ),
          ]
        : _operations;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.inter(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dataTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          columns: const [
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Operation')),
            DataColumn(label: Text('Details')),
            DataColumn(label: Text('Status')),
          ],
          rows: rows.map((record) {
            final statusColor = switch (record.status) {
              'Completed' => Colors.green,
              'Completed w/ Errors' => Colors.orange,
              'Failed' => Colors.redAccent,
              _ => Colors.white54,
            };
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp),
                  ),
                ),
                DataCell(Text(record.operation)),
                DataCell(Text(record.details)),
                DataCell(
                  Text(
                    record.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BulkOperationRecord {
  final DateTime timestamp;
  final String operation;
  final String details;
  final String status;

  const _BulkOperationRecord({
    required this.timestamp,
    required this.operation,
    required this.details,
    required this.status,
  });
}
