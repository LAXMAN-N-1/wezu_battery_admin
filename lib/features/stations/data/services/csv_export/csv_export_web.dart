// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:csv/csv.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../models/maintenance_event.dart';

class CsvExportService {
  static void exportMaintenanceData(List<MaintenanceEvent> events) {
    if (events.isEmpty) return;

    List<List<dynamic>> rows = [
      [
        'ID',
        'Station',
        'Title',
        'Type',
        'Status',
        'Crew',
        'Start Time',
        'End Time',
        'Description',
      ],
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

    String csvData = Csv().encode(rows);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        "download",
        "maintenance_records_${DateTime.now().millisecondsSinceEpoch}.csv",
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
