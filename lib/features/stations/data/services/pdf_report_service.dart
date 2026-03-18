import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/maintenance_checklist.dart';
import '../models/maintenance_event.dart';

class PdfReportService {
  static Future<void> generateMaintenanceReport({
    required MaintenanceEvent event,
    required ChecklistTemplate template,
    required ChecklistSubmission submission,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(event),
              pw.SizedBox(height: 20),
              _buildSummary(event, template, submission),
              pw.SizedBox(height: 20),
              pw.Text('Maintenance Checklist Details', 
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _buildChecklist(submission.completedTasks),
              pw.Spacer(),
              _buildFooter(submission),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Maintenance_Report_${event.stationName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> generateComplianceSummaryReport({
    required List<MaintenanceEvent> events,
    required int complianceRate,
    required int completedTasks,
    required int overdueTasks,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildSummaryHeader(),
            pw.SizedBox(height: 20),
            _buildDashboardStats(complianceRate, completedTasks, overdueTasks),
            pw.SizedBox(height: 30),
            pw.Text('Overdue Maintenance Alerts', 
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            _buildOverdueList(events.where((e) => e.status == MaintenanceStatus.scheduled && e.startTime.isBefore(DateTime.now())).toList()),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Compliance_Summary_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildSummaryHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Compliance Summary Report', 
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('WeZu Battery Admin System', style: pw.TextStyle(color: PdfColors.grey700)),
          ],
        ),
        pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}'),
      ],
    );
  }

  static pw.Widget _buildDashboardStats(int rate, int completed, int overdue) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildStatBox('Compliance Rate', '$rate%', PdfColors.green),
        _buildStatBox('Completed', completed.toString(), PdfColors.blue),
        _buildStatBox('Overdue', overdue.toString(), PdfColors.red),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildOverdueList(List<MaintenanceEvent> overdue) {
    if (overdue.isEmpty) {
      return pw.Text('No overdue maintenance tasks at this time.', style: const pw.TextStyle(color: PdfColors.green700));
    }
    return pw.Column(
      children: overdue.map((e) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey200),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(e.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Station: ${e.stationName} • Due: ${e.startTime.toString().split('.')[0]}', 
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.Text('OVERDUE', style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildHeader(MaintenanceEvent event) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Station Maintenance Compliance Report', 
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('WeZu Battery Admin System', style: pw.TextStyle(color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
            pw.Text('ID: ${event.id}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(MaintenanceEvent event, ChecklistTemplate template, ChecklistSubmission submission) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Maintenance Overview', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Row(children: [pw.Text('Station: '), pw.Text(event.stationName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
          pw.Row(children: [pw.Text('Template: '), pw.Text(template.name)]),
          pw.Row(children: [pw.Text('Type: '), pw.Text(event.type.name.toUpperCase())]),
          pw.Row(children: [pw.Text('Technician: '), pw.Text(submission.submittedBy)]),
          pw.Row(children: [pw.Text('Status: '), pw.Text('COMPLIANT', style: pw.TextStyle(color: PdfColors.green900, fontWeight: pw.FontWeight.bold))]),
        ],
      ),
    );
  }

  static pw.Widget _buildChecklist(List<ChecklistTask> tasks) {
    return pw.Column(
      children: tasks.map((task) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 15,
                height: 15,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey),
                  color: task.isCompleted ? PdfColors.green : null,
                ),
                child: task.isCompleted 
                  ? pw.Center(child: pw.Text('v', style: pw.TextStyle(color: PdfColors.white, fontSize: 10))) 
                  : null,
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(task.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(task.description, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    if (task.note != null && task.note!.isNotEmpty)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 2),
                        padding: const pw.EdgeInsets.all(5),
                        color: PdfColors.grey100,
                        child: pw.Text('Note: ${task.note}', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildFooter(ChecklistSubmission submission) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Digitally Signed by: ${submission.submittedBy}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Timestamp: ${submission.submittedAt}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }
}
