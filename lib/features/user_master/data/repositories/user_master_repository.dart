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

  String _normalizeRoleToken(String? raw) {
    if (raw == null) return '';
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool _matchesRole(Map<String, dynamic> userJson, String selectedRole) {
    final target = _normalizeRoleToken(selectedRole);
    if (target.isEmpty) return true;

    final candidates = <String>{
      _normalizeRoleToken(userJson['role']?.toString()),
      _normalizeRoleToken(userJson['role_name']?.toString()),
      _normalizeRoleToken(userJson['user_type']?.toString()),
    };

    final isSuperuser =
        userJson['is_superuser'] == true ||
        userJson['is_superuser']?.toString().toLowerCase() == 'true';
    if (isSuperuser) {
      candidates.add('super_admin');
    }

    final roleList = userJson['roles'];
    if (roleList is List) {
      for (final role in roleList) {
        candidates.add(_normalizeRoleToken(role?.toString()));
      }
    }

    if (target == 'super_admin') {
      return candidates.contains('super_admin') ||
          candidates.contains('operations_admin') ||
          candidates.contains('security_admin') ||
          candidates.contains('finance_admin');
    }

    if (target == 'manager') {
      return candidates.contains('manager') ||
          candidates.contains('operations_admin') ||
          candidates.contains('support_manager') ||
          candidates.contains('dealer_manager') ||
          candidates.contains('logistics_manager') ||
          candidates.contains('fleet_manager') ||
          candidates.contains('warehouse_manager') ||
          candidates.contains('finance_manager');
    }

    if (target == 'read_only') {
      return candidates.contains('read_only') ||
          candidates.contains('readonly') ||
          candidates.contains('viewer') ||
          candidates.contains('auditor');
    }

    if (target == 'support_agent') {
      return candidates.contains('support_agent') ||
          candidates.contains('support_manager');
    }

    return candidates.contains(target);
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

      final originalItems =
          ((raw['items'] ?? raw['users']) as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();

      final filteredItems = (role != null && role.trim().isNotEmpty)
          ? originalItems.where((item) => _matchesRole(item, role)).toList()
          : originalItems;

      return {
        'items': filteredItems,
        'total_count': filteredItems.length,
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
      try {
        final data = await getUsers(skip: 0, limit: 5000);
        final rows = (data['items'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();

        int active = 0;
        int suspended = 0;
        int pending = 0;
        int inactive = 0;

        for (final row in rows) {
          final status = row['status']?.toString().toLowerCase() ?? '';
          if (status == 'active') active++;
          if (status == 'suspended') suspended++;
          if (status == 'pending' || status == 'pending_verification') {
            pending++;
          }
          if (status == 'inactive') inactive++;
        }

        return <String, dynamic>{
          'total_users': rows.length,
          'active_count': active,
          'inactive_count': inactive,
          'suspended_count': suspended,
          'pending_count': pending,
        };
      } catch (_) {
        return <String, dynamic>{
          'total_users': 0,
          'active_count': 0,
          'inactive_count': 0,
          'suspended_count': 0,
          'pending_count': 0,
        };
      }
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
      try {
        final response = await _apiClient.post(
          '/api/v1/admin/users/create',
          data: data,
        );
        return User.fromJson(response.data);
      } catch (_) {
        throw Exception('Failed to create user: $e');
      }
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
      try {
        final response = await _apiClient.get('/api/v1/admin/roles/');
        final list = (response.data as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((json) => Role.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        return list;
      } catch (_) {
        throw Exception('Failed to load roles: $e');
      }
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
      try {
        final response = await _apiClient.post(
          '/api/v1/admin/roles/',
          data: data,
        );
        return response.data;
      } catch (_) {
        throw Exception('Failed to create role: $e');
      }
    }
  }

  Future<Map<String, dynamic>> updateRole(
    int roleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/admin/rbac/roles/$roleId',
        data: data,
      );
      return response.data;
    } catch (e) {
      try {
        final response = await _apiClient.put(
          '/api/v1/admin/roles/$roleId',
          data: data,
        );
        return response.data;
      } catch (_) {
        throw Exception('Failed to update role: $e');
      }
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
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final modules = data['modules'] as List? ?? const <dynamic>[];
        return modules
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      try {
        final response = await _apiClient.get(
          '/api/v1/admin/roles/permissions',
        );
        final rows = (response.data as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry));

        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final perm in rows) {
          final module = perm['module']?.toString() ?? 'general';
          grouped
              .putIfAbsent(module, () => <Map<String, dynamic>>[])
              .add(<String, dynamic>{
                'id': perm['slug']?.toString() ?? '',
                'slug': perm['slug']?.toString() ?? '',
                'label':
                    perm['description']?.toString() ??
                    perm['slug']?.toString() ??
                    '',
                'action': perm['action']?.toString() ?? '',
              });
        }

        return grouped.entries
            .map(
              (entry) => <String, dynamic>{
                'module': entry.key,
                'label': entry.key
                    .split('_')
                    .map(
                      (word) => word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '',
                    )
                    .join(' '),
                'permissions': entry.value,
              },
            )
            .toList();
      } catch (_) {
        throw Exception('Failed to load permissions: $e');
      }
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
