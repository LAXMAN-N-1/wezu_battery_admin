import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvService {
  static Future<void> downloadCsv(List<List<dynamic>> rows, String fileName) async {
    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csvData);
    
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'Exported Data: $fileName'
    );
  }
}
