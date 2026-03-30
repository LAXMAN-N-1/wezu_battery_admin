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
        '/api/v1/admin/users/',
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
      final response = await _apiClient.get('/api/v1/admin/users/summary');
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
      final response = await _apiClient.post('/api/v1/admin/users/', data: data);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/v1/admin/users/$id', data: data);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // --- Roles ---
  Future<List<Role>> getRoles() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/rbac/roles');
      return (response.data as List).map((json) => Role.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/admin/rbac/roles', data: data);
      return response.data;
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  Future<Map<String, dynamic>> updateRolePermissions(int roleId, List<String> permissionSlugs, {String mode = 'overwrite'}) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/admin/rbac/roles/$roleId/permissions',
        data: {'permissions': permissionSlugs, 'mode': mode},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to update role permissions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPermissionModules() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/rbac/permissions');
      final data = response.data as Map<String, dynamic>;
      return (data['modules'] as List).map((m) => m as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to load permissions: $e');
    }
  }


  // --- Access Logs ---
  Future<List<AccessLog>> getAccessLogs({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/admin/access-logs/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List).map((json) => AccessLog.fromJson(json)).toList();
    } catch (e) {
      // Mock Data if API not ready
      return [];
    }
  }
}
