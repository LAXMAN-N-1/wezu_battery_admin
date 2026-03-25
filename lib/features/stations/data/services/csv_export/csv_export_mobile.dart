import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/maintenance_event.dart';

class CsvExportService {
  static Future<void> exportMaintenanceData(List<MaintenanceEvent> events) async {
    if (events.isEmpty) return;

    List<List<dynamic>> rows = [
      ['ID', 'Station', 'Title', 'Type', 'Status', 'Crew', 'Start Time', 'End Time', 'Description']
    ];

    for (var event in events) {
      rows.add([
        event.id,
        event.stationName,
        event.title,
        event.type.name,
        event.status.name,
        event.assignedCrew ?? 'Unassigned',
        event.startTime.toIso8601String(),
        event.endTime.toIso8601String(),
        event.description,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/maintenance_records_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Maintenance Records Export');
  }
}
