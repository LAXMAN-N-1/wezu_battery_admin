// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:convert';
import 'package:csv/csv.dart';

class CsvService {
  static Future<void> downloadCsv(
    List<List<dynamic>> rows,
    String fileName,
  ) async {
    final csvData = Csv().encode(rows);
    await downloadCsvString(csvData, fileName);
  }

  static Future<void> downloadCsvString(String csvData, String fileName) async {
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
