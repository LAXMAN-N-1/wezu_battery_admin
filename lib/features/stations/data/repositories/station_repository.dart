import '../../../../core/api/api_client.dart';
import '../models/station.dart';
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
  }
}
