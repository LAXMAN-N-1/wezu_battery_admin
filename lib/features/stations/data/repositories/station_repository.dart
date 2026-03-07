import '../../../../core/api/api_client.dart';
import '../models/station.dart';
import '../models/station_specs.dart';
import '../models/station_performance.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class StationRepository {
  final ApiClient _apiClient;

  StationRepository(this._apiClient);

  Future<Options> _getOptions() async {
    final token = await _apiClient.storage.read(key: 'admin_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ---- Stations ----

  Future<List<Station>> getStations() async {
    final response = await _apiClient.get(
      'admin/stations/', // Added trailing slash to match backend @router.get("/")
      options: await _getOptions(),
    );
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
      'admin/stations/', // Added trailing slash to match backend @router.post("/")
      data: station.toJson(),
      options: await _getOptions(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Station.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to add station: ${response.data}');
  }

  Future<Station> updateStation(Station station) async {
    final response = await _apiClient.put(
      'admin/stations/${station.id}',
      data: station.toJson(),
      options: await _getOptions(),
    );
    if (response.statusCode == 200) {
      return Station.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to update station: ${response.data}');
  }

  Future<void> deleteStation(int id) async {
    final response = await _apiClient.delete(
      'admin/stations/$id',
      options: await _getOptions(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete station: ${response.data}');
    }
  }

  // ---- Station Specs ----

  Future<StationSpecs> getSpecs(int stationId) async {
    try {
      final response = await _apiClient.get(
        'admin/stations/$stationId/specs',
        options: await _getOptions(),
      );
      if (response.statusCode == 200) {
        return StationSpecs.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return StationSpecs.defaults(stationId);
  }

  Future<void> saveSpecs(int stationId, StationSpecs specs) async {
    final response = await _apiClient.put(
      'admin/stations/$stationId/specs',
      data: specs.toJson(),
      options: await _getOptions(),
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
    final startStr =
        DateFormat('yyyy-MM-ddTHH:mm:ss').format(start ?? DateTime.now().subtract(const Duration(days: 30)));
    final endStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(end ?? DateTime.now());

    final response = await _apiClient.get(
      'admin/analytics/stations/$stationId/performance',
      queryParameters: {'start_date': startStr, 'end_date': endStr},
      options: await _getOptions(),
    );

    if (response.statusCode == 200) {
      return StationPerformance.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch performance metrics: ${response.data}');
  }

  Future<List<StationRanking>> getStationRankings({
    String metric = 'revenue',
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      'admin/analytics/stations/ranking',
      queryParameters: {'metric': metric, 'limit': limit},
      options: await _getOptions(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = response.data;
      return list
          .map((e) => StationRanking.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch station rankings: ${response.data}');
  }
}
