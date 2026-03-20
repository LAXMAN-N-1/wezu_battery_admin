import '../../../../core/api/api_client.dart';
import '../models/station.dart';
import '../models/maintenance_model.dart';
import '../models/station_specs.dart';
import '../models/station_performance.dart';
import '../models/station_alert.dart';
import '../models/charging_queue.dart';

class StationRepository {
  final ApiClient _api;

  StationRepository([ApiClient? api]) : _api = api ?? ApiClient();

  // ---- STATIONS ----

  Future<List<Station>> getStations() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/');
      final data = response.data;
      if (data is List) {
        return data.map((json) => Station.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('stations')) {
        return (data['stations'] as List).map((json) => Station.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStationsPaginated({
    int skip = 0,
    int limit = 100,
    String? search,
    String? status,
    String? city,
    String? stationType,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (stationType != null && stationType.isNotEmpty) params['station_type'] = stationType;

    try {
      final response = await _api.get('/api/v1/admin/stations/', queryParameters: params);
      final data = response.data;
      if (data is Map && data.containsKey('stations')) {
        return {
          'stations': (data['stations'] as List).map((json) => Station.fromJson(json)).toList(),
          'total_count': data['total_count'] ?? 0,
        };
      }
      return {'stations': <Station>[], 'total_count': 0};
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

  Future<Station> addStation(Station station) async {
    final response = await _api.post('/api/v1/admin/stations/', data: {
      'name': station.name,
      'address': station.address,
      'latitude': station.latitude,
      'longitude': station.longitude,
      'status': station.status,
      'total_slots': station.totalSlots,
      'contact_phone': station.contactPhone,
    });
    return Station.fromJson(response.data);
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
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'station_type': stationType,
        'total_slots': totalSlots,
        'power_rating_kw': powerRatingKw,
        'contact_phone': contactPhone,
        'is_24x7': is24x7,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateStation(Station station) async {
    await _api.put('/api/v1/admin/stations/${station.id}', data: {
      'name': station.name,
      'address': station.address,
      'latitude': station.latitude,
      'longitude': station.longitude,
      'status': station.status,
      'total_slots': station.totalSlots,
      'contact_phone': station.contactPhone,
    });
  }

  Future<bool> updateStationData(int id, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/v1/admin/stations/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteStation(int id) async {
    await _api.delete('/api/v1/admin/stations/$id');
  }

  Future<bool> deleteStationBoolean(int id) async {
    try {
      await _api.delete('/api/v1/admin/stations/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getAllPerformance() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/performance');
      final data = response.data;
      if (data is Map) {
        return {
          'stations': (data['stations'] as List).map((json) => StationPerformanceSummary.fromJson(json)).toList(),
          'summary': data['summary'] ?? {},
        };
      } else if (data is List) {
        return {
          'stations': data.map((json) => StationPerformanceSummary.fromJson(json)).toList(),
          'summary': {},
        };
      }
      return {'stations': <StationPerformanceSummary>[], 'summary': {}};
    } catch (e) {
      return {'stations': <StationPerformanceSummary>[], 'summary': {}};
    }
  }

  Future<StationPerformance> getStationPerformance(int stationId, {DateTime? start, DateTime? end}) async {
    try {
      final params = <String, dynamic>{};
      if (start != null) params['start_date'] = start.toIso8601String();
      if (end != null) params['end_date'] = end.toIso8601String();
      final response = await _api.get('/api/v1/admin/stations/$stationId/performance', queryParameters: params);
      return StationPerformance.fromJson(response.data);
    } catch (e) {
      return StationPerformance.defaults(stationId);
    }
  }

  Future<List<StationRanking>> getStationRankings({String metric = 'revenue', int limit = 10}) async {
    try {
      final params = {'metric': metric, 'limit': limit};
      final response = await _api.get('/api/v1/admin/stations/rankings', queryParameters: params);
      final data = response.data;
      if (data is List) {
        return data.map((json) => StationRanking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<BackendStationAlert>> getStationAlerts(int stationId) async {
    try {
      final response = await _api.get('/api/v1/admin/stations/$stationId/alerts');
      final data = response.data;
      if (data is List) {
        return data.map((json) => BackendStationAlert.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<ChargingQueueResponse> getChargingQueue(int stationId) async {
    try {
      final response = await _api.get('/api/v1/admin/stations/$stationId/queue');
      return ChargingQueueResponse.fromJson(response.data);
    } catch (e) {
      return ChargingQueueResponse(stationId: stationId.toString(), capacity: 0, currentQueue: []);
    }
  }

  // ---- MAINTENANCE ----

  Future<Map<String, dynamic>> getMaintenanceRecords({String? status}) async {
    final params = status != null ? {'status': status} : null;
    try {
      final response = await _api.get('/api/v1/admin/stations/maintenance/', queryParameters: params);
      final data = response.data;
      if (data is Map) {
        return {
          'records': (data['records'] as List).map((json) => MaintenanceRecord.fromJson(json)).toList(),
          'total_count': data['total_count'] ?? 0,
        };
      }
      return {'records': <MaintenanceRecord>[], 'total_count': 0};
    } catch (e) {
      return {'records': <MaintenanceRecord>[], 'total_count': 0};
    }
  }

  Future<MaintenanceStats> getMaintenanceStats() async {
    try {
      final response = await _api.get('/api/v1/admin/stations/maintenance/stats');
      return MaintenanceStats.fromJson(response.data);
    } catch (e) {
      return const MaintenanceStats(totalRecords: 0, completed: 0, scheduled: 0, inProgress: 0, totalCost: 0.0, stationsInMaintenance: 0);
    }
  }

  Future<bool> createMaintenanceRecord({
    required int entityId,
    required String description,
    String? maintenanceType,
    double cost = 0,
    String status = 'scheduled',
  }) async {
    try {
      await _api.post('/api/v1/admin/stations/maintenance/', data: {
        'entity_id': entityId,
        'entity_type': 'station',
        'description': description,
        'maintenance_type': maintenanceType,
        'cost': cost,
        'status': status,
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

  // ---- SPECS ----

  Future<StationSpecs> getSpecs(int stationId) async {
    try {
      final response = await _api.get('/api/v1/admin/stations/$stationId/specs');
      return StationSpecs.fromJson(response.data);
    } catch (e) {
      return StationSpecs.defaults(stationId);
    }
  }

  Future<bool> saveSpecs(int stationId, StationSpecs specs) async {
    try {
      await _api.put('/api/v1/admin/stations/$stationId', data: specs.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }
}
