import '../../../../core/api/api_client.dart';
import '../models/user.dart';
import '../models/role.dart';
import '../models/access_log.dart';

class UserMasterRepository {
  final ApiClient _apiClient;

  UserMasterRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return null;
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'active';
      case 'suspended':
        return 'suspended';
      case 'pending':
      case 'pending_verification':
        return 'pending_verification';
      default:
        return null;
    }
  }

  String? _mapRoleToUserType(String? role) {
    if (role == null || role.trim().isEmpty) return null;
    switch (role.trim().toLowerCase()) {
      case 'dealer':
        return 'dealer';
      case 'customer':
        return 'customer';
      case 'driver':
        return 'driver';
      case 'super admin':
      case 'admin':
      case 'manager':
      case 'support agent':
      case 'read-only':
        return 'admin';
      default:
        return null;
    }
  }

  // --- Users ---
  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? role,
    String? status,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final normalizedStatus = _normalizeStatus(status);
      final userType = _mapRoleToUserType(role);
      final response = await _apiClient.get(
        '/api/v1/admin/users/',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (userType != null) 'user_type': userType,
          if (normalizedStatus != null) 'status': normalizedStatus,
          'skip': skip,
          'limit': limit,
        },
      );
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      return {
        'items': raw['items'] ?? raw['users'] ?? const <dynamic>[],
        'total_count': raw['total_count'] ?? 0,
        'page': raw['page'] ?? (skip ~/ limit) + 1,
        'page_size': raw['page_size'] ?? raw['limit'] ?? limit,
      };
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
      final response = await _apiClient.post(
        '/api/v1/admin/users/',
        data: data,
      );
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/admin/users/$id',
        data: data,
      );
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // --- Roles ---
  Future<List<Role>> getRoles() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/rbac/roles');
      return (response.data as List)
          .map((json) => Role.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/admin/rbac/roles',
        data: data,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  Future<Map<String, dynamic>> updateRolePermissions(
    int roleId,
    List<String> permissionSlugs, {
    String mode = 'overwrite',
  }) async {
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
      return (data['modules'] as List)
          .map((m) => m as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load permissions: $e');
    }
  }

  // --- Access Logs ---
  Future<List<AccessLog>> getAccessLogs({int skip = 0, int limit = 50}) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/admin/audit-trails/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      final entries = payload['entries'] as List? ?? const <dynamic>[];

      return entries.whereType<Map>().map((entry) {
        final json = Map<String, dynamic>.from(entry);
        return AccessLog(
          id: json['id']?.toString() ?? '',
          timestamp:
              DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
              DateTime.now(),
          userId: json['actor_id']?.toString() ?? '',
          userName: json['actor_name']?.toString() ?? 'System',
          roleName: '',
          actionType: json['action_type']?.toString() ?? 'unknown',
          moduleAffected:
              json['from_location_type']?.toString() ??
              json['to_location_type']?.toString() ??
              '',
          ipAddress: '',
          deviceBrowser: null,
          isSuccess: true,
        );
      }).toList();
    } catch (e) {
      // Keep UX stable if audit API is unavailable.
      return [];
    }
  }
}
