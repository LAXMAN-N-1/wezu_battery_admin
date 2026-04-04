import '../../../../core/api/api_client.dart';
import '../models/role.dart';

class RoleRepository {
  final ApiClient _api = ApiClient();
  
  // Cache permissions locally for synchronous utility methods
  List<Permission> _cachedPermissions = [];

  Future<List<Role>> getRoles({
    int skip = 0,
    int limit = 100,
    String? category,
    bool activeOnly = false,
    bool includePermissions = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'active_only': activeOnly,
        'include_permissions': includePermissions,
      };
      if (category != null) queryParams['category'] = category;

      final response = await _api.get('/api/v1/admin/rbac/roles', queryParameters: queryParams);
      final data = response.data as List;
      return data.map((json) => Role.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching roles: $e");
      return [];
    }
  }

  Future<Role?> getRoleDetail(int roleId) async {
    try {
      final response = await _api.get('/api/v1/admin/rbac/roles/$roleId');
      return Role.fromJson(response.data);
    } catch (e) {
      print("Error fetching role detail for $roleId: $e");
      return null;
    }
  }

  Future<List<Permission>> getPermissions({int skip = 0, int limit = 1000}) async {
    try {
      final queryParams = {'skip': skip, 'limit': limit};
      final response = await _api.get('/api/v1/admin/rbac/permissions', queryParameters: queryParams);
      
      // The response might be { "modules": [...] } as per spec or a direct list
      List data;
      if (response.data is Map && response.data['modules'] != null) {
        // Spec says grouped by module, but our model expects a flat list for now.
        // I'll flatten it or handle accordingly.
        data = [];
        for (var module in (response.data['modules'] as List)) {
          if (module['permissions'] != null) {
            data.addAll(module['permissions']);
          }
        }
      } else if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      
      _cachedPermissions = data.map((json) => Permission.fromJson(json)).toList();
      return _cachedPermissions;
    } catch (e) {
      print("Error fetching permissions: $e");
      return [];
    }
  }

  Future<Permission> createPermission({
    required String slug,
    required String module,
    required String action,
    required String description,
    String scope = 'all',
  }) async {
    final response = await _api.post('/api/v1/admin/rbac/permissions', data: {
      'slug': slug,
      'module': module,
      'action': action,
      'description': description,
      'scope': scope,
    });
    return Permission.fromJson(response.data);
  }

  Future<Role> createRole({
    required String name,
    required String description,
    String category = 'custom',
    int level = 0,
    bool isActive = true,
    int? parentId,
    List<int> permissionIds = const [],
  }) async {
    final response = await _api.post('/api/v1/admin/rbac/roles', data: {
      'name': name,
      'description': description,
      'category': category,
      'level': level,
      'is_active': isActive,
      'permission_ids': permissionIds,
      if (parentId != null) 'parent_id': parentId,
    });
    return Role.fromJson(response.data);
  }

  Future<Role> updateRole(int roleId, {
    String? name,
    String? description,
    String? category,
    int? level,
    bool? isActive,
    int? parentId,
    List<String>? permissions,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    if (level != null) data['level'] = level;
    if (isActive != null) data['is_active'] = isActive;
    if (parentId != null) data['parent_id'] = parentId;
    if (permissions != null) data['permissions'] = permissions;

    final response = await _api.put('/api/v1/admin/rbac/roles/$roleId', data: data);
    return Role.fromJson(response.data);
  }

  Future<void> deleteRole(int roleId) async {
    await _api.delete('/api/v1/admin/rbac/roles/$roleId');
  }

  Future<Map<String, dynamic>> getRolePermissions(int roleId) async {
    final response = await _api.get('/api/v1/admin/rbac/roles/$roleId/permissions');
    return response.data;
  }

  Future<Map<String, dynamic>> assignPermissionsToRole(int roleId, List<String> permissions, {String mode = 'overwrite'}) async {
    final response = await _api.post('/api/v1/admin/rbac/roles/$roleId/permissions', data: {
      'permissions': permissions,
      'mode': mode,
    });
    return response.data;
  }

  Future<List<dynamic>> getUserRoles(int userId) async {
    final response = await _api.get('/api/v1/admin/rbac/users/$userId/roles');
    return response.data as List;
  }

  Future<Map<String, dynamic>> assignRoleToUser(int userId, {
    required int roleId,
    DateTime? effectiveFrom,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final data = {
      'role_id': roleId,
      if (effectiveFrom != null) 'effective_from': effectiveFrom.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
    final response = await _api.post('/api/v1/admin/rbac/users/$userId/roles', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> bulkAssignRoles(int roleId, List<int> userIds) async {
    final response = await _api.post('/api/v1/admin/rbac/roles/bulk-assign', data: {
      'role_id': roleId,
      'user_ids': userIds,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> transferRole(int sourceUserId, {required int targetUserId, required int roleId, String? reason}) async {
    final response = await _api.post('/api/v1/admin/rbac/users/$sourceUserId/roles/transfer', data: {
      'new_user_id': targetUserId,
      'role_id': roleId,
      'reason': reason ?? 'Admin transfer',
    });
    return response.data;
  }

  Future<void> removeRoleFromUser(int userId, int roleId) async {
    await _api.delete('/api/v1/admin/rbac/users/$userId/roles/$roleId');
  }

  Future<Map<String, dynamic>> checkPermission(int userId, String permission, {int? resourceId}) async {
    final queryParams = {
      'permission': permission,
      if (resourceId != null) 'resource_id': resourceId,
    };
    final response = await _api.get('/api/v1/admin/rbac/users/$userId/permissions/check', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getUserPermissions(int userId) async {
    final response = await _api.get('/api/v1/admin/rbac/users/$userId/permissions');
    return response.data;
  }

  Future<Role> duplicateRole(int roleId, {required String newName, String? description}) async {
    final response = await _api.post('/api/v1/admin/rbac/roles/$roleId/duplicate', data: {
      'new_name': newName,
      if (description != null) 'description': description,
    });
    return Role.fromJson(response.data);
  }

  Future<List<dynamic>> getRoleHierarchy() async {
    final response = await _api.get('/api/v1/admin/rbac/hierarchy');
    return response.data as List;
  }

  // Access Paths
  Future<Map<String, dynamic>> assignAccessPath(int userId, String pattern, String level) async {
    final response = await _api.post('/api/v1/admin/rbac/users/$userId/access-paths', data: {
      'path_pattern': pattern,
      'access_level': level,
    });
    return response.data;
  }

  Future<List<dynamic>> getUserAccessPaths(int userId) async {
    final response = await _api.get('/api/v1/admin/rbac/users/$userId/access-paths');
    return response.data as List;
  }

  Future<void> removeAccessPath(int userId, int pathId) async {
    await _api.delete('/api/v1/admin/rbac/users/$userId/access-paths/$pathId');
  }

  Future<Map<String, dynamic>> updateAccessPath(int userId, int pathId, String level) async {
    final response = await _api.put('/api/v1/admin/rbac/users/$userId/access-paths/$pathId', data: {
      'access_level': level,
    });
    return response.data;
  }

  Future<void> togglePermission(Role role, List<String> currentPermissions, String permissionSlug) async {
      final perms = List<String>.from(currentPermissions);
      if (perms.contains(permissionSlug)) {
        perms.remove(permissionSlug);
      } else {
        perms.add(permissionSlug);
      }
      await assignPermissionsToRole(role.id, perms);
  }

  /// Get permission categories for grouped display
  List<String> getPermissionCategories() {
    return _cachedPermissions.map((p) => p.category).toSet().toList();
  }

  List<Permission> getPermissionsByCategory(String category) {
    return _cachedPermissions.where((p) => p.category == category).toList();
  }
}
