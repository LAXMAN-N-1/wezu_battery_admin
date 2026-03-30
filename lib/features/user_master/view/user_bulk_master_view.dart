import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/admin_ui_components.dart';

class UserBulkMasterView extends StatelessWidget {
  const UserBulkMasterView({super.key});

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
              subtitle: 'Mass manage user profiles, roles, and assignments via CSV/Excel sheets.',
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
            Text('Recent Operations', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.upload_file, size: 40, color: Colors.blue)),
          const SizedBox(height: 16),
          Text('Import Users', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Upload a CSV file to add or update multiple users at once.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          // Drag and Drop Zone Placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3), style: BorderStyle.none),
            ),
            // Custom dashed border simulation
            child: CustomPaint(
              painter: DashedRectPainter(color: Colors.blue.withValues(alpha: 0.5)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.blueAccent),
                    const SizedBox(height: 12),
                    const Text('Drag & drop your CSV file here', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('or', style: TextStyle(color: Colors.white38)),
                    const SizedBox(height: 4),
                    TextButton(onPressed: () {}, child: const Text('Browse Files', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 16, color: Colors.white70),
            label: const Text('Download CSV Template', style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
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
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.download_for_offline, size: 40, color: Colors.green)),
          const SizedBox(height: 16),
          Text('Export Users', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Download your complete user database or a filtered subset for analysis.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          _exportOption('All Users', 'Export the entire user list (approx. 1,245 rows)'),
          const SizedBox(height: 12),
          _exportOption('Filtered Users', 'Export only users matching current filters'),
          const SizedBox(height: 12),
          _exportOption('Roles & Permissions', 'Export the system permission matrix'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
             onPressed: () {},
             icon: const Icon(Icons.file_download, color: Colors.white, size: 18),
             label: const Text('Generate Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          ),
        ],
      ),
    );
  }

  Widget _exportOption(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
               ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentOpsTable() {
    return Container(
       width: double.infinity,
       decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
       child: DataTable(
          headingTextStyle: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
          dataTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          columns: const [
             DataColumn(label: Text('Date & Time')),
             DataColumn(label: Text('Operation')),
             DataColumn(label: Text('Initiated By')),
             DataColumn(label: Text('Records')),
             DataColumn(label: Text('Status')),
          ],
          rows: const [
             DataRow(cells: [DataCell(Text('Today, 10:45 AM')), DataCell(Text('Users Export (CSV)', style: TextStyle(fontWeight: FontWeight.bold))), DataCell(Text('Laxman')), DataCell(Text('1,245')), DataCell(Text('Completed', style: TextStyle(color: Colors.green)))]),
             DataRow(cells: [DataCell(Text('Yesterday, 14:20')), DataCell(Text('Dealers Import (Excel)', style: TextStyle(fontWeight: FontWeight.bold))), DataCell(Text('Laxman')), DataCell(Text('45 added, 2 failed')), DataCell(Text('Completed w/ Errors', style: TextStyle(color: Colors.orange)))]),
          ],
       ),
    );
  }
}

// Simple custom dashed rect painter
class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Simplistic dash around edges
    const dash = 8.0;
    const gap = 6.0;

    // Top
    for(double i = 0; i < size.width; i += dash + gap) { canvas.drawLine(Offset(i, 0), Offset(i + dash, 0), paint); }
    // Bottom
    for(double i = 0; i < size.width; i += dash + gap) { canvas.drawLine(Offset(i, size.height), Offset(i + dash, size.height), paint); }
    // Left
    for(double i = 0; i < size.height; i += dash + gap) { canvas.drawLine(Offset(0, i), Offset(0, i + dash), paint); }
    // Right
    for(double i = 0; i < size.height; i += dash + gap) { canvas.drawLine(Offset(size.width, i), Offset(size.width, i + dash), paint); }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
