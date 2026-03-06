import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../features/dashboard/provider/dashboard_provider.dart';

class ExportService {
  static Future<String?> exportDashboardToCSV(DashboardMetrics metrics) async {
    try {
      final buffer = StringBuffer();

      // --- KPI Summary ---
      buffer.writeln('KPI Summary');
      buffer.writeln('Metric,Value,Last Updated');
      buffer.writeln(
        'Total Rentals,${metrics.totalRentals},${metrics.lastUpdated}',
      );
      buffer.writeln(
        'Revenue,${metrics.revenue.replaceAll(',', '')},${metrics.lastUpdated}',
      );
      buffer.writeln(
        'Active Users,${metrics.activeUsers},${metrics.lastUpdated}',
      );
      buffer.writeln(
        'Fleet Utilization,${metrics.fleetUtilization},${metrics.lastUpdated}',
      );
      buffer.writeln('');

      // --- Station Revenue ---
      buffer.writeln('Revenue by Station');
      buffer.writeln('Station Name,Revenue (₹),Volume');
      for (var station in metrics.stationRevenue) {
        buffer.writeln('${station.name},${station.revenue},${station.volume}');
      }
      buffer.writeln('');

      // --- Battery Type Revenue ---
      buffer.writeln('Revenue by Battery Type');
      buffer.writeln('Battery Type,Revenue (₹)');
      for (var battery in metrics.batteryTypeRevenue) {
        buffer.writeln('${battery.type},${battery.revenue}');
      }
      buffer.writeln('');

      // --- Trend Analysis ---
      buffer.writeln('Trend Analysis - Daily');
      buffer.writeln('Label,Revenue,Rentals,Users,Health (%)');
      for (var i = 0; i < metrics.dailyRevenue.length; i++) {
        buffer.writeln(
          '${metrics.dailyRevenue[i].label},${metrics.dailyRevenue[i].value},${metrics.dailyRentals[i].value},${metrics.dailyUsers[i].value},${metrics.dailyHealth[i].value}',
        );
      }
      buffer.writeln('');

      buffer.writeln('Conversion Funnel');
      buffer.writeln('Stage,Count,Conversion Rate (%)');
      for (var i = 0; i < metrics.funnelStages.length; i++) {
        final stage = metrics.funnelStages[i];
        final rate = (stage.count / metrics.funnelStages[0].count * 100);
        buffer.writeln(
          '${stage.label},${stage.count},${rate.toStringAsFixed(1)}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/wezu_admin_analytics_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
