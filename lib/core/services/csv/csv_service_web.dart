import 'dart:html' as html;
import 'dart:convert';
import 'package:csv/csv.dart';

class CsvService {
  static Future<void> downloadCsv(List<List<dynamic>> rows, String fileName) async {
    String csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.csv")
      ..click();
      
    html.Url.revokeObjectUrl(url);
  }
}
