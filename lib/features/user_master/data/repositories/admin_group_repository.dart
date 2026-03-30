import '../../../../core/api/api_client.dart';
import '../models/admin_group_model.dart';

class AdminGroupRepository {
  final ApiClient _apiClient;

  AdminGroupRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<AdminGroupModel>> getGroups() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/groups/');
      return (response.data as List).map((json) => AdminGroupModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load admin groups: $e');
    }
  }

  Future<AdminGroupModel> createGroup(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/admin/groups/', data: data);
      return AdminGroupModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create admin group: $e');
    }
  }
}
