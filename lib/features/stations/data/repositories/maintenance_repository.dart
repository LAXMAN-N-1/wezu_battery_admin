import '../../../../core/api/api_client.dart';
import '../models/maintenance_model.dart';

class MaintenanceRepository {
  final ApiClient _api = ApiClient();

  Future<List<MaintenanceRecord>> getAllMaintenanceRecords() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/maintenance/all');
      final data = response.data;
      if (data is List) {
        return data.map((e) => MaintenanceRecord.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching maintenance records: $e');
      return [];
    }
  }

  Future<MaintenanceStats> getStats(List<MaintenanceRecord> records) async {
    int completed = records.where((r) => r.status == 'completed').length;
    int scheduled = records.where((r) => r.status == 'scheduled').length;
    int inProgress = records.where((r) => r.status == 'in_progress').length;
    double totalCost = records.fold(0.0, (sum, r) => sum + r.cost);
    return MaintenanceStats(
      total: records.length,
      completed: completed,
      scheduled: scheduled,
      inProgress: inProgress,
      totalCost: totalCost,
    );
  }

  Future<bool> createMaintenanceRecord({
    required int entityId,
    required String maintenanceType,
    required String description,
    required double cost,
  }) async {
    try {
      await _api.post('/api/v1/admin/stations/maintenance/create', data: {
        'entity_type': 'station',
        'entity_id': entityId,
        'technician_id': 1,
        'maintenance_type': maintenanceType,
        'description': description,
        'cost': cost,
      });
      return true;
    } catch (e) {
      print('Error creating maintenance record: $e');
      return false;
    }
  }

  Future<bool> updateStatus(int recordId, String newStatus) async {
    try {
      await _api.put('/api/v1/admin/stations/maintenance/$recordId/status', data: {
        'status': newStatus,
      });
      return true;
    } catch (e) {
      print('Error updating maintenance status: $e');
      return false;
    }
  }
}
