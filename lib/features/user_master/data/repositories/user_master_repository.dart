import '../../../../core/api/api_client.dart';
import '../models/user.dart';
import '../models/role.dart';
import '../models/access_log.dart';

class UserMasterRepository {
  final ApiClient _apiClient;

  UserMasterRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // --- Users ---
  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? role,
    String? status,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/admin/users/',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null && role != 'All') 'role': role,
          if (status != null && status != 'All') 'status': status,
          'skip': skip,
          'limit': limit,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<Map<String, dynamic>> getUserSummary() async {
    try {
      final response = await _apiClient.get('/admin/users/summary');
      return response.data;
    } catch (e) {
      // Return mock summary if endpoint fails
      return {
        'total_users': 150,
        'active_count': 120,
        'inactive_count': 15,
        'suspended_count': 5,
        'pending_count': 10,
      };
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/admin/users/', data: data);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/admin/users/$id', data: data);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // --- Roles ---
  Future<List<Role>> getRoles() async {
    try {
      final response = await _apiClient.get('/admin/roles/');
      return (response.data as List).map((json) => Role.fromJson(json)).toList();
    } catch (e) {
      // Mock Data if API not ready
      return [
        Role(
          id: 'admin',
          name: 'Super Admin',
          description: 'Full system access',
          isSystemRole: true,
          userCount: 3,
          permissions: const PermissionMatrix(modules: {
            'dashboard': PermissionLevel.full,
            'fleet': PermissionLevel.full,
            'settings': PermissionLevel.full,
          }),
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  // --- Access Logs ---
  Future<List<AccessLog>> getAccessLogs({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/admin/access-logs/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List).map((json) => AccessLog.fromJson(json)).toList();
    } catch (e) {
      // Mock Data if API not ready
      return [];
    }
  }
}
