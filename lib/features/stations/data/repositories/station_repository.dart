import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/station.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(ref.read(apiClientProvider));
});

class StationRepository {
  final ApiClient _apiClient;

  StationRepository(this._apiClient);

  Future<List<Station>> getStations() async {
    final response = await _apiClient.get('/api/v1/stations/');
    if (response.data is List) {
      return (response.data as List).map((e) => Station.fromJson(e)).toList();
    }
    return [];
  }
}
