import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/user.dart';
import '../models/role.dart';
import '../models/access_log.dart';

class UserMasterRepository {
  final ApiClient _apiClient;
  static const String _rbacBase = '/api/v1/rbac';

  UserMasterRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return null;
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'active';
      case 'inactive':
        return 'inactive';
      case 'suspended':
        return 'suspended';
      case 'pending':
      case 'pending verification':
      case 'pending_verification':
        return 'pending_verification';
      default:
        return null;
    }
  }

  String? _normalizeUserType(String? userType) {
    if (userType == null || userType.trim().isEmpty) return null;
    switch (userType.trim().toLowerCase()) {
      case 'admin':
      case 'super admin':
      case 'operations admin':
      case 'security admin':
      case 'finance admin':
      case 'manager':
      case 'support manager':
      case 'read-only':
        return 'admin';
      case 'dealer':
      case 'dealer owner':
        return 'dealer';
      case 'dealer staff':
      case 'dealer_staff':
      case 'dealer manager':
      case 'dealer inventory staff':
      case 'dealer finance staff':
      case 'dealer support staff':
        return 'dealer_staff';
      case 'support agent':
      case 'support_agent':
        return 'support_agent';
      case 'logistics':
      case 'driver':
      case 'dispatcher':
      case 'fleet manager':
      case 'warehouse manager':
      case 'logistics manager':
        return 'logistics';
      case 'customer':
        return 'customer';
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
    final userType = _normalizeUserType(role);
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

  Future<User> getUserById(String id) async {
    final response = await _apiClient.get('/api/v1/admin/users/$id');
    return User.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/admin/users', data: data);
      return User.fromJson(response.data);
    } on Exception {
      final response = await _apiClient.post(
        '/api/v1/admin/users/create',
        data: data,
      );
      return User.fromJson(response.data);
    }
  }

  Future<Map<String, dynamic>> createSupabaseUser(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post('/api/v1/admin/users', data: data);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getDealersReference() async {
    final response = await _apiClient.get(
      '/api/v1/admin/dealers/',
      queryParameters: {'limit': 200},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final rows = payload['dealers'] as List? ?? const <dynamic>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStationsReference({
    int? dealerId,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/admin/stations/',
      queryParameters: {
        'limit': 300,
        if (dealerId != null) 'dealer_id': dealerId,
      },
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final rows = payload['stations'] as List? ?? const <dynamic>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getWarehousesReference() async {
    final response = await _apiClient.get(
      '/api/v1/warehouses/',
      queryParameters: {'limit': 300},
    );
    final rows = response.data as List? ?? const <dynamic>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '/api/v1/admin/users/$id',
      data: data,
    );
    return User.fromJson(response.data);
  }

  Future<void> suspendUser(String id, {required String reason}) async {
    await _apiClient.put(
      '/api/v1/admin/users/$id/suspend',
      data: {'reason': reason},
    );
  }

  Future<void> reactivateUser(String id) async {
    await _apiClient.put('/api/v1/admin/users/$id/reactivate');
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.delete('/api/v1/admin/users/$id');
  }

  Future<List<Role>> getRoles() async {
    final response = await _apiClient.get('$_rbacBase/roles');
    return (response.data as List).map((json) => Role.fromJson(json)).toList();
  }

  Future<List<Role>> getUserCreationRoles() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/admin/users/creation-roles',
      );
      return (response.data as List)
          .map((json) => Role.fromJson(json))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return await getRoles();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    final response = await _apiClient.post('$_rbacBase/roles', data: data);
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
      '$_rbacBase/roles/$roleId/permissions',
      data: {'permissions': permissionSlugs, 'mode': mode},
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getPermissionModules() async {
    final response = await _apiClient.get('$_rbacBase/permissions');
    if (response.data is List) {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final raw in (response.data as List).whereType<Map>()) {
        final permission = Map<String, dynamic>.from(raw);
        final module = permission['module']?.toString() ?? 'general';
        grouped.putIfAbsent(module, () => []).add(permission);
      }
      return grouped.entries
          .map(
            (entry) => {
              'module': entry.key,
              'label': entry.key
                  .split('_')
                  .map(
                    (w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : '',
                  )
                  .join(' '),
              'permissions': entry.value,
            },
          )
          .toList();
    }

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final modules = data['modules'] as List? ?? const <dynamic>[];
    return modules
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<List<AccessLog>> getAccessLogs({int skip = 0, int limit = 50}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/security/login-activity',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final entries = payload['items'] as List? ?? const <dynamic>[];
    return entries
        .whereType<Map>()
        .map((entry) => AccessLog.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
