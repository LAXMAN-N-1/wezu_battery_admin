import '../../models/maintenance_event.dart';

abstract class CsvExportServiceBase {
  void exportMaintenanceData(List<MaintenanceEvent> events);
}
