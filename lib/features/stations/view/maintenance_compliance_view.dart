import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/providers/maintenance_provider.dart';
import '../data/providers/checklist_provider.dart';
import '../data/models/maintenance_event.dart';
import '../data/models/maintenance_checklist.dart';
import '../data/services/pdf_report_service.dart';
import '../data/services/csv_export/csv_export.dart';
import 'maintenance_execution_view.dart';

class MaintenanceComplianceView extends ConsumerWidget {
  const MaintenanceComplianceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceAsync = ref.watch(maintenanceNotifierProvider);
    final submissionsAsync = ref.watch(checklistSubmissionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Compliance Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
            onPressed: () => maintenanceAsync.whenData((events) {
              final completed = events.where((e) => e.status == MaintenanceStatus.completed).length;
              final now = DateTime.now();
              final overdue = events.where((e) => e.status == MaintenanceStatus.scheduled && e.startTime.isBefore(now)).length;
              final rate = events.isEmpty ? 0 : (completed / events.length * 100).toInt();
              
              PdfReportService.generateComplianceSummaryReport(
                events: events,
                complianceRate: rate,
                completedTasks: completed,
                overdueTasks: overdue,
              );
            }),
            tooltip: 'Export PDF Summary',
          ),
          IconButton(
            icon: const Icon(Icons.grid_on, color: Colors.greenAccent),
            onPressed: () => maintenanceAsync.whenData((events) {
              CsvExportService.exportMaintenanceData(events);
            }),
            tooltip: 'Export CSV Records',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: maintenanceAsync.when(
        data: (events) => submissionsAsync.when(
          data: (submissions) => _buildContent(context, events, submissions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MaintenanceEvent> events, List<dynamic> submissions) {
    final now = DateTime.now();
    final completed = events.where((e) => e.status == MaintenanceStatus.completed).length;
    final overdue = events.where((e) => e.status == MaintenanceStatus.scheduled && e.startTime.isBefore(now)).length;
    final complianceRate = events.isEmpty ? 0 : (completed / events.length * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(completed, overdue, complianceRate),
          const SizedBox(height: 32),
          Text('Compliance Trends', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildTrendChart(),
          const SizedBox(height: 32),
          Text('Critical Alerts', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildAlertsList(events.where((e) => e.status == MaintenanceStatus.scheduled && e.startTime.isBefore(now)).toList()),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int completed, int overdue, int rate) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Compliance Rate', '$rate%', Icons.verified_user, Colors.green),
        _buildStatCard('Completed Tasks', completed.toString(), Icons.check_circle, Colors.blue),
        _buildStatCard('Overdue Tasks', overdue.toString(), Icons.warning, Colors.redAccent),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: const TextStyle(color: Colors.white38, fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y}% Compliance',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 65),
                FlSpot(1, 72),
                FlSpot(2, 68),
                FlSpot(3, 85),
                FlSpot(4, 80),
                FlSpot(5, 92),
                FlSpot(6, 88),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<MaintenanceEvent> overdueEvents) {
    if (overdueEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            Text('All maintenance is up to date', style: TextStyle(color: Colors.green.withValues(alpha: 0.7))),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: overdueEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = overdueEvents[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Station: ${event.stationName} • Due: ${event.startTime.toString().split('.')[0]}', 
                         style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      final templates = ref.read(checklistTemplateNotifierProvider).value ?? [];
                      if (templates.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No checklist templates available. Please create one first.')),
                        );
                        return;
                      }

                      // Try robust matching based on maintenance type string
                      final targetType = event.type.name.toLowerCase();
                      ChecklistTemplate? template;
                      
                      try {
                        template = templates.firstWhere(
                          (t) => t.maintenanceType.toLowerCase() == targetType,
                        );
                      } catch (_) {
                        // Fallback: try matching station type if maintenance type fails
                        try {
                          template = templates.firstWhere(
                            (t) => t.stationType.toLowerCase() == event.stationName.toLowerCase().split(' ').first.toLowerCase(),
                            orElse: () => templates.first,
                          );
                        } catch (_) {
                          template = templates.first;
                        }
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaintenanceExecutionView(event: event, template: template!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Resolve'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
