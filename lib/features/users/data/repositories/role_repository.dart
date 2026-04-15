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
      final response = await _api.get('/api/v1/admin/rbac/roles/');
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
      final response = await _api.get('/api/v1/admin/rbac/roles/permissions');
      final data = response.data as List;
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
    final response = await _api.post('/api/v1/admin/rbac/roles/', data: {
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
    final ids = newPermissionIds ?? 
                role.permissions.map((p) => p is int ? p : (p as Map<String, dynamic>)['id'] as int).toList();
    
    final response = await _api.put('/api/v1/admin/rbac/roles/${role.id}', data: {
      'name': role.name,
      'description': role.description,
      'is_active': role.isActive,
      'permission_ids': ids,
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
