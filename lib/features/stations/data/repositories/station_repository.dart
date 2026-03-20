import '../../../../core/api/api_client.dart';
import '../models/station.dart';
import '../models/maintenance_model.dart';

class StationRepository {
  final ApiClient _api = ApiClient();

  // ---- STATIONS ----

  Future<Map<String, dynamic>> getStations({
    int skip = 0,
    int limit = 100,
    String? search,
    String? status,
    String? city,
    String? stationType,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (city != null) params['city'] = city;
    if (stationType != null) params['station_type'] = stationType;

    try {
      final response = await _api.get('/api/v1/admin/stations/', queryParameters: params);
      final data = response.data;
      final stations = (data['stations'] as List).map((s) => Station.fromJson(s)).toList();
      return {'stations': stations, 'total_count': data['total_count'] ?? stations.length};
    } catch (e) {
      return {'stations': <Station>[], 'total_count': 0};
    }
  }

  Future<Map<String, dynamic>> getStationStats() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'total_stations': 0, 'operational': 0, 'maintenance': 0,
        'offline': 0, 'total_slots': 0, 'avg_rating': 0.0,
      };
    }
  }

  Future<bool> createStation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? city,
    String stationType = 'automated',
    int totalSlots = 0,
    double? powerRatingKw,
    String? contactPhone,
    bool is24x7 = false,
  }) async {
    try {
      await _api.post('/api/v1/admin/stations/', data: {
        'name': name, 'address': address, 'latitude': latitude, 'longitude': longitude,
        'city': city, 'station_type': stationType, 'total_slots': totalSlots,
        'power_rating_kw': powerRatingKw, 'contact_phone': contactPhone, 'is_24x7': is24x7,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStation(int stationId, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/v1/admin/stations/$stationId', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStation(int stationId) async {
    try {
      await _api.delete('/api/v1/admin/stations/$stationId');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---- PERFORMANCE ----

  Future<Map<String, dynamic>> getAllPerformance() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/performance/all');
      final data = response.data;
      final stations = (data['stations'] as List).map((s) => StationPerformance.fromJson(s)).toList();
      return {'stations': stations, 'summary': data['summary']};
    } catch (e) {
      return {'stations': <StationPerformance>[], 'summary': {}};
    }
  }

  // ---- MAINTENANCE ----

  Future<Map<String, dynamic>> getMaintenanceRecords({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit, 'entity_type': 'station'};
    if (status != null) params['status'] = status;

    try {
      final response = await _api.get('/api/v1/admin/stations/maintenance/all', queryParameters: params);
      final data = response.data;
      final records = (data['records'] as List).map((r) => MaintenanceRecord.fromJson(r)).toList();
      return {'records': records, 'total_count': data['total_count'] ?? records.length};
    } catch (e) {
      return {'records': <MaintenanceRecord>[], 'total_count': 0};
    }
  }

  Future<MaintenanceStats> getMaintenanceStats() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/maintenance/stats');
      return MaintenanceStats.fromJson(response.data);
    } catch (e) {
      return const MaintenanceStats(
        totalRecords: 0, completed: 0, scheduled: 0,
        inProgress: 0, totalCost: 0.0, stationsInMaintenance: 0,
      );
    }
  }

  Future<bool> createMaintenanceRecord({
    required int entityId,
    required String description,
    String maintenanceType = 'preventive',
    double cost = 0.0,
    String status = 'scheduled',
  }) async {
    try {
      await _api.post('/api/v1/admin/stations/maintenance/create', data: {
        'entity_type': 'station', 'entity_id': entityId,
        'maintenance_type': maintenanceType, 'description': description,
        'cost': cost, 'status': status,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMaintenanceStatus(int recordId, String newStatus) async {
    try {
      await _api.put('/api/v1/admin/stations/maintenance/$recordId/status?new_status=$newStatus');
      return true;
    } catch (e) {
      return false;
    }
  }
}
