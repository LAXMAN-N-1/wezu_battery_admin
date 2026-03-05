import '../../../../core/api/api_client.dart';
import '../models/station.dart';
import '../models/station_specs.dart';

class StationRepository {
  final ApiClient _apiClient;

  StationRepository(this._apiClient);

  // ---- Stations ----

  Future<List<Station>> getStations() async {
    final response = await _apiClient.get('/admin/stations/');
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
      '/admin/stations',
      data: station.toJson(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Station.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to add station: ${response.data}');
  }

  Future<Station> updateStation(Station station) async {
    final response = await _apiClient.put(
      '/admin/stations/${station.id}',
      data: station.toJson(),
    );
    if (response.statusCode == 200) {
      return Station.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to update station: ${response.data}');
  }

  Future<void> deleteStation(int id) async {
    final response = await _apiClient.delete('/admin/stations/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete station: ${response.data}');
    }
  }

  // ---- Station Specs ----

  Future<StationSpecs> getSpecs(int stationId) async {
    try {
      final response = await _apiClient.get('/admin/stations/$stationId/specs');
      if (response.statusCode == 200) {
        return StationSpecs.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return StationSpecs.defaults(stationId);
  }

  Future<void> saveSpecs(int stationId, StationSpecs specs) async {
    final response = await _apiClient.put(
      '/admin/stations/$stationId/specs',
      data: specs.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save specs: ${response.data}');
    }
  }
}
