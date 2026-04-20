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

  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? role,
    String? status,
    int skip = 0,
    int limit = 20,
  }) async {
    final normalizedStatus = _normalizeStatus(status);
    final userType = _mapRoleToUserType(role);
    final response = await _apiClient.get(
      '/api/v1/admin/users',
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
  }

  Future<Map<String, dynamic>> getUserSummary() async {
    final response = await _apiClient.get('/api/v1/admin/users/summary');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/admin/users/create',
        data: data,
      );
      return User.fromJson(response.data);
    } on Exception {
      final response = await _apiClient.post('/api/v1/admin/users', data: data);
      return User.fromJson(response.data);
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '/api/v1/admin/users/$id',
      data: data,
    );
    return User.fromJson(response.data);
  }

  Future<List<Role>> getRoles() async {
    final response = await _apiClient.get('/api/v1/admin/rbac/roles');
    final payload = response.data;

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((json) => Role.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    if (payload is Map) {
      final normalized = Map<String, dynamic>.from(payload);
      final rawList =
          normalized['items'] ?? normalized['roles'] ?? const <dynamic>[];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((json) => Role.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    }

    return const <Role>[];
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/api/v1/admin/rbac/roles',
      data: data,
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateRolePermissions(
    int roleId,
    List<String> permissionSlugs, {
    String mode = 'overwrite',
  }) async {
    final response = await _apiClient.post(
      '/api/v1/admin/rbac/roles/$roleId/permissions',
      data: {'permissions': permissionSlugs, 'mode': mode},
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getPermissionModules() async {
    final response = await _apiClient.get('/api/v1/admin/rbac/permissions');
    final payload = response.data;

    List<Map<String, dynamic>> modules = const <Map<String, dynamic>>[];

    if (payload is List) {
      modules = payload
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } else if (payload is Map) {
      final data = Map<String, dynamic>.from(payload);
      final rawModules =
          data['modules'] ?? data['items'] ?? data['permissions'];
      if (rawModules is List) {
        modules = rawModules
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    }

    if (modules.isEmpty) {
      // Keep Permission Matrix renderable even when backend shape changes
      // or permission modules endpoint is temporarily unavailable.
      final roles = await getRoles();
      final roleDerivedModules = <String>{
        for (final role in roles) ...role.permissions.modules.keys,
      };
      modules = roleDerivedModules
          .where((name) => name.trim().isNotEmpty)
          .map(
            (name) => <String, dynamic>{
              'module': name,
              'label': name.replaceAll('_', ' '),
              'permissions': const <Map<String, dynamic>>[],
            },
          )
          .toList();
    }

    return modules;
  }

  Future<List<AccessLog>> getAccessLogs({int skip = 0, int limit = 50}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/security/audit-logs',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final entries = payload['items'] as List? ?? const <dynamic>[];

    return entries.whereType<Map>().map((entry) {
      final json = Map<String, dynamic>.from(entry);
      return AccessLog(
        id: json['id']?.toString() ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        userId: json['user_id']?.toString() ?? '',
        userName: json['user_id'] != null
            ? 'User #${json['user_id']}'
            : 'System',
        roleName: '',
        actionType: json['action']?.toString() ?? 'unknown',
        moduleAffected: json['resource_type']?.toString() ?? '',
        ipAddress: json['ip_address']?.toString() ?? '',
        deviceBrowser: json['user_agent']?.toString(),
        isSuccess: true,
      );
    }).toList();
  }
}
