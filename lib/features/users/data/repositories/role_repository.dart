import '../../../../core/api/api_client.dart';
import '../models/role.dart';
import 'dart:math';

class RoleRepository {
  final ApiClient _api = ApiClient();

  // Cache permissions locally for synchronous utility methods
  List<Permission> _cachedPermissions = [];
  final Map<int, String> _permissionIdToSlug = {};

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
      for (final roleEntry in data.whereType<Map>()) {
        final roleMap = Map<String, dynamic>.from(roleEntry);
        final permissions = roleMap['permissions'];
        if (permissions is! List) continue;
        for (final permissionEntry in permissions.whereType<Map>()) {
          final permissionMap = Map<String, dynamic>.from(permissionEntry);
          final id = permissionMap['id'];
          final slug = permissionMap['slug']?.toString();
          if (id is int && slug != null && slug.isNotEmpty) {
            _permissionIdToSlug[id] = slug;
          }
        }
      }
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
      final response = await _api.get('/api/v1/admin/rbac/permissions');
      final payload = response.data;

      final modules = payload is Map<String, dynamic>
          ? payload['modules'] as List<dynamic>?
          : payload is Map
          ? (payload['modules'] as List<dynamic>?)
          : null;

      if (modules == null) {
        _cachedPermissions = [];
        return [];
      }

      final permissions = <Permission>[];
      final slugToId = <String, int>{};
      for (final entry in _permissionIdToSlug.entries) {
        slugToId[entry.value] = entry.key;
      }
      
      var generatedId = _permissionIdToSlug.keys.isEmpty
          ? 1
          : _permissionIdToSlug.keys.reduce(max) + 1;

      for (final moduleEntry in modules) {
        if (moduleEntry is! Map) continue;
        final moduleMap = Map<String, dynamic>.from(moduleEntry);
        final moduleName =
            moduleMap['module']?.toString() ??
            moduleMap['label']?.toString() ??
            'general';
        final modulePermissions = moduleMap['permissions'];
        if (modulePermissions is! List) continue;

        for (final permissionEntry in modulePermissions) {
          if (permissionEntry is! Map) continue;
          final permissionMap = Map<String, dynamic>.from(permissionEntry);
          final slug = permissionMap['id']?.toString() ?? '';
          if (slug.isEmpty) continue;
          final id = slugToId[slug] ?? generatedId++;
          slugToId[slug] = id;

          final permission = Permission(
            id: id,
            slug: slug,
            module: permissionMap['resource']?.toString() ?? moduleName,
            action: permissionMap['action']?.toString() ?? '',
            description: permissionMap['description']?.toString() ?? '',
          );

          _permissionIdToSlug[id] = slug;
          permissions.add(permission);
        }
      }

      _cachedPermissions = permissions;
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
    final permissionSlugs = await _permissionSlugsFromIds(permissionIds);

    final response = await _api.post('/api/v1/admin/rbac/roles', data: {
      'name': name,
      'description': description,
      'category': category,
      'level': level,
      'is_active': isActive,
      'permissions': permissionSlugs,
      if (parentId != null) 'parent_id': parentId,
    });
    return Role.fromJson(response.data);
  }

  Future<Role> updateRole(Role role, {List<int>? newPermissionIds}) async {
    final ids = newPermissionIds ?? _extractPermissionIds(role.permissions);
    final permissionSlugs = await _permissionSlugsFromIds(ids);

    final response = await _api.put(
      '/api/v1/admin/rbac/roles/${role.id}',
      data: {
        'name': role.name,
        'description': role.description,
        'is_active': role.isActive,
        'permissions': permissionSlugs,
      },
    );
    return Role.fromJson(response.data);
  }

  Future<void> deleteRole(int roleId) async {
    await _api.delete('/api/v1/admin/rbac/roles/$roleId');
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

  Future<void> togglePermission(Role role, int permissionId) async {
    final perms = _extractPermissionIds(role.permissions);
    if (perms.contains(permissionId)) {
      perms.remove(permissionId);
    } else {
      perms.add(permissionId);
    }
    await updateRole(role, newPermissionIds: perms);
  }

  Future<List<String>> _permissionSlugsFromIds(List<int> ids) async {
    if (ids.isEmpty) return <String>[];
    if (_permissionIdToSlug.isEmpty) {
      await getPermissions();
    }

    final slugs = <String>[];
    for (final id in ids) {
      final slug = _permissionIdToSlug[id];
      if (slug != null && slug.isNotEmpty) {
        slugs.add(slug);
      }
    }
    return slugs.toSet().toList();
  }

  int? _permissionIdFromSlug(String slug) {
    for (final entry in _permissionIdToSlug.entries) {
      if (entry.value == slug) {
        return entry.key;
      }
    }
    return null;
  }

  List<int> _extractPermissionIds(List<dynamic> permissions) {
    final ids = <int>{};
    for (final permission in permissions) {
      if (permission is int) {
        ids.add(permission);
        continue;
      }
      if (permission is String) {
        final id = _permissionIdFromSlug(permission);
        if (id != null) ids.add(id);
        continue;
      }
      if (permission is Map) {
        final rawId = permission['id'];
        if (rawId is int) {
          ids.add(rawId);
          continue;
        }
        if (rawId != null) {
          final id = _permissionIdFromSlug(rawId.toString());
          if (id != null) ids.add(id);
        }
      }
    }
    return ids.toList();
  }
  /// Get permission categories for grouped display
  List<String> getPermissionCategories() {
    return _cachedPermissions.map((p) => p.category).toSet().toList();
  }

  List<Permission> getPermissionsByCategory(String category) {
    return _cachedPermissions.where((p) => p.category == category).toList();
  }
}
