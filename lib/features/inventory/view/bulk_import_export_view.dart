import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:google_fonts/google_fonts.dart';

import '../provider/bulk_provider.dart';
import '../data/repositories/inventory_repository.dart';

class BulkImportExportView extends ConsumerStatefulWidget {
  const BulkImportExportView({super.key});

  @override
  ConsumerState<BulkImportExportView> createState() =>
      _BulkImportExportViewState();
}

class _BulkImportExportViewState extends ConsumerState<BulkImportExportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryRepository _repository = InventoryRepository();

  bool _isDragging = false;

  // Export states
  String _exportStatus = 'All';
  String _exportType = 'All';
  String _exportLocation = 'All';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      ref.read(bulkImportProvider.notifier).setFile(result.files.first);
    }
  }

  void _runValidation() {
    ref.read(bulkImportProvider.notifier).runValidation();
  }

  void _confirmImport() {
    ref.read(bulkImportProvider.notifier).confirmImport();
  }

  Future<void> _runExport() async {
    setState(() => _isExporting = true);
    try {
      await _repository.exportBatteries(
        status: _exportStatus,
        batteryType: _exportType,
        locationType: _exportLocation,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export downloaded successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Header
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFF3B82F6),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Bulk Import (CSV)'),
              Tab(text: 'Export Data (CSV)'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildImportTab(), _buildExportTab()],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 1. IMPORT TAB
  // ==========================================
  Widget _buildImportTab() {
    final state = ref.watch(bulkImportProvider);

    if (state.uploadSuccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 24),
            Text(
              'Successfully Imported!',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.validRows} batteries added to inventory.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(bulkImportProvider.notifier).clearFile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text(
                'Import Another File',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload / Status Panel
          Expanded(
            flex: 2,
            child: _buildUploadPanel(state),
          ),
          const SizedBox(width: 24),
          // Validation Results Panel
          Expanded(
            flex: 3,
            child: _buildValidationPanel(state),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildUploadPanel(state),
        const SizedBox(height: 24),
        _buildValidationPanel(state),
      ],
    );
  }

  Widget _buildUploadPanel(BulkImportState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload CSV File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a CSV file containing battery records. You can run validation before final insertion.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Dropzone
          DropTarget(
            onDragDone: (detail) {
              detail.files.first.readAsBytes().then((bytes) {
                final fileWithBytes = PlatformFile(
                  name: detail.files.first.name,
                  size: bytes.length,
                  bytes: bytes,
                );
                ref.read(bulkImportProvider.notifier).setFile(fileWithBytes);
              });
            },
            onDragEntered: (detail) => setState(() => _isDragging = true),
            onDragExited: (detail) => setState(() => _isDragging = false),
            child: GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDragging
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: _isDragging ? const Color(0xFF3B82F6) : Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.selectedFile != null
                          ? state.selectedFile!.name
                          : 'Click to browse or drag & drop CSV',
                      style: TextStyle(
                        color: state.selectedFile != null ? Colors.white : Colors.white54,
                        fontWeight: state.selectedFile != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (state.selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${(state.selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (state.selectedFile != null)
                TextButton(
                  onPressed: () => ref.read(bulkImportProvider.notifier).clearFile(),
                  child: const Text('Clear', style: TextStyle(color: Colors.white54)),
                ),
              if (state.selectedFile != null) const SizedBox(width: 16),
              if (state.selectedFile != null && !state.dryRunComplete)
                ElevatedButton.icon(
                  icon: state.isParsing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.playlist_play, color: Colors.white),
                  label: Text(
                    state.isParsing ? 'Validating...' : 'Run Validation',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: state.isParsing ? null : _runValidation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              if (state.dryRunComplete)
                ElevatedButton.icon(
                  icon: state.isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    state.isUploading ? 'Importing...' : 'Confirm Import',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: state.isUploading ? null : _confirmImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationPanel(BulkImportState state) {
    return Container(
      height: 500, // Fixed height for vertical scroll within validation
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: Colors.white70),
                const SizedBox(width: 12),
                const Text(
                  'Validation Results (Dry Run)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (state.dryRunComplete) ...[
                  const Spacer(),
                  _buildStatusPill('${state.validRows} Valid', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatusPill('${state.errors.length} Errors', state.errors.isEmpty ? Colors.grey : Colors.red),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          Expanded(
            child: !state.dryRunComplete
                ? const Center(
                    child: Text(
                      'Run validation to see results here',
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : state.errors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 48, color: Colors.green.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text('All rows passed validation!', style: TextStyle(color: Colors.green)),
                            const SizedBox(height: 8),
                            Text(
                              'Ready to import ${state.validRows} batteries.',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.errors.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                        itemBuilder: (context, index) {
                          final err = state.errors[index] as Map<String, dynamic>;
                          final serial = err['serial'] ?? 'Unknown Serial';
                          final msg = err['error'] ?? 'Unknown Error';
                          return ListTile(
                            leading: const Icon(Icons.error_outline, color: Colors.redAccent),
                            title: Text(
                              'Serial: $serial',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // 2. EXPORT TAB
  // ==========================================
  Widget _buildExportTab() {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.download, size: 28, color: Colors.white),
                SizedBox(width: 16),
                Text(
                  'Export Inventory Data',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select filters below to narrow down the dataset before exporting. A CSV file will be generated and downloaded to your machine.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),

            _buildDropdown(
              label: 'Status',
              value: _exportStatus,
              items: ['All', 'Available', 'In_Use', 'Maintenance', 'Retired'],
              onChanged: (v) => setState(() => _exportStatus = v!),
            ),
            const SizedBox(height: 24),
            _buildDropdown(
              label: 'Battery Type',
              value: _exportType,
              items: ['All', '48V/30Ah', '60V/40Ah', '72V/50Ah'],
              onChanged: (v) => setState(() => _exportType = v!),
            ),
            const SizedBox(height: 24),
            _buildDropdown(
              label: 'Location',
              value: _exportLocation,
              items: [
                'All',
                'Warehouse',
                'Station',
                'With_Customer',
                'In_Transit',
              ],
              onChanged: (v) => setState(() => _exportLocation = v!),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download, color: Colors.white),
                label: Text(
                  _isExporting ? 'Generating CSV...' : 'Export to CSV',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: _isExporting ? null : _runExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white54,
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
