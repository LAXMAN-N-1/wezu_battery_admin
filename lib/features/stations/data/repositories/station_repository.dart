import '../../../../core/api/api_client.dart';
import '../models/station.dart';
<<<<<<< HEAD
import '../models/station_specs.dart';
import '../models/station_performance.dart';
import '../models/station_alert.dart';
import '../models/charging_queue.dart';
import '../models/station_status.dart';

class StationRepository {
  final ApiClient _apiClient;

  StationRepository(this._apiClient);

  // ---- Stations ----
  Future<List<Station>> getStations() async {
    // Use the primary management endpoint instead of the IoT snapshot
    // to ensure CRUD operations (like delete) are reflected immediately.
    final response = await _apiClient.get('admin/main/stations');
    if (response.statusCode == 200) {
      final List<dynamic> list = response.data;
      return list
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Station> addStation(Station station) async {
    final response = await _apiClient.post(
      'admin/main/stations', 
      data: station.toJson(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Station.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to add station: ${response.data}');
  }

  Future<Station> updateStation(Station station) async {
    final response = await _apiClient.put(
      'admin/main/stations/${station.id}',
      data: station.toJson(),
    );
    if (response.statusCode == 200) {
      return Station.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to update station: ${response.data}');
  }

  Future<void> deleteStation(int id) async {
    final response = await _apiClient.delete('admin/main/stations/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete station: ${response.data}');
    }
  }

  // ---- Station Specs ----
  // No per-station specs endpoint found in openapi.json, using defaults or future implementation path
  Future<StationSpecs> getSpecs(int stationId) async {
    try {
      final response = await _apiClient.get('admin/main/stations/$stationId/specs');
      if (response.statusCode == 200) {
        return StationSpecs.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return StationSpecs.defaults(stationId);
  }

  Future<void> saveSpecs(int stationId, StationSpecs specs) async {
    final response = await _apiClient.put(
      'admin/main/stations/$stationId/specs',
      data: specs.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save specs: ${response.data}');
    }
  }

  // ---- Performance & Analytics ----

  Future<StationPerformance> getStationPerformance(
    int stationId, {
    DateTime? start,
    DateTime? end,
  }) async {
    // Note: No granular per-station performance endpoint found, 
    // using analytics dashboard as a fallback or future path.
    try {
      final response = await _apiClient.get('admin/main/stations/$stationId/performance');
      if (response.statusCode == 200) {
        return StationPerformance.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    // Return a default performance object instead of throwing during integration
    return StationPerformance.defaults(stationId);
  }

  Future<List<StationRanking>> getStationRankings({
    String metric = 'revenue',
    int limit = 10,
  }) async {
    final response = await _apiClient.get('admin/analytics/top-stations');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> list = data['stations'] ?? [];
      return list
          .map((e) => StationRanking.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ---- Alerts & Monitoring ----

  Future<List<BackendStationAlert>> getStationAlerts(int stationId) async {
    // Mapping to IoT logs as a source of alerts
    final response = await _apiClient.get(
      'admin/main/iot/stations/logs',
      queryParameters: {'station_id': stationId, 'limit': 10},
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = response.data;
      return list
          .map((e) => BackendStationAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ---- Charging Queue ----

  Future<ChargingQueueResponse> getChargingQueue(int stationId) async {
    // Fallback to a stub if not available in current backend
    try {
      final response = await _apiClient.get('admin/main/stations/$stationId/charging-queue');
      if (response.statusCode == 200) {
        return ChargingQueueResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return ChargingQueueResponse(
      stationId: stationId.toString(),
      capacity: 0,
      currentQueue: [],
    );
  }

  // ---- Maintenance (Official Admin Routes) ----

  Future<List<MaintenanceSchedule>> getMaintenance(int stationId) async {
    final response = await _apiClient.get('maintenance/history');
    if (response.statusCode == 200) {
      final List<dynamic> list = response.data;
      return list
          .where((e) => (e['entity_id'] as num?)?.toInt() == stationId)
          .map((e) => MaintenanceSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createMaintenance(int stationId, Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      'maintenance/record',
      data: {
        ...data,
        'entity_id': stationId,
        'entity_type': 'station',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create maintenance: ${response.data}');
    }
  }

  Future<void> updateMaintenanceStatus(int stationId, int taskId, String status) async {
    // Fallback: the current API uses records which are usually 'completed'
    // Maintenance updates are limited in the current spec.
  }

  Future<void> deleteMaintenanceTask(int stationId, int taskId) async {
    // Current API focuses on history/records, delete might not be supported.
  }

  // ---- Demand Forecast ----
  Future<Map<String, dynamic>> getDemandForecast(int stationId) async {
    final response = await _apiClient.get('ml/demand/forecast/$stationId');
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    return {};
=======
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
>>>>>>> origin/main
  }
}
