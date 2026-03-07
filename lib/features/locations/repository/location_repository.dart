import '../../../core/api/api_client.dart';
import '../model/location_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.read(apiClientProvider));
});

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository(this._apiClient);

  Future<List<LocationNode>> fetchLocations(LocationLevel level) async {
    final response = await _apiClient.get('locations/${level.name}s');
    return (response.data as List).map((e) => LocationNode.fromJson(e)).toList();
  }

  Future<LocationNode> createLocation(LocationLevel level, String name, int? parentId) async {
    Map<String, dynamic> data = {'name': name};
    
    // Add parent ID based on level
    switch (level) {
      case LocationLevel.continent: break;
      case LocationLevel.country: data['continent_id'] = parentId; break;
      case LocationLevel.region: data['country_id'] = parentId; break;
      case LocationLevel.city: data['region_id'] = parentId; break;
      case LocationLevel.zone: data['city_id'] = parentId; break;
    }

    final response = await _apiClient.post('locations/${level.name}s', data: data);
    return LocationNode.fromJson(response.data);
  }
}
