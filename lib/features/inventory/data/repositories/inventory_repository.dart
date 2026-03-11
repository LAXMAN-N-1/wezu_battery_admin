
import '../models/battery.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/battery.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.read(apiClientProvider));
});

class InventoryRepository {
  final ApiClient _apiClient;

  InventoryRepository(this._apiClient);

  Future<List<Battery>> getBatteries() async {
    final response = await _apiClient.get('/api/v1/batteries/');
    if (response.data is List) {
      return (response.data as List).map((e) => Battery.fromJson(e)).toList();
    }
    return [];
  }
}
