import 'dart:math';

import '../../../../core/api/api_client.dart';
import '../models/role.dart';

class RoleRepository {
  final ApiClient _api = ApiClient();

  List<Permission> _cachedPermissions = [];
  final Map<int, String> _permissionIdToSlug = {};

  Future<List<Role>> getRoles() async {
    final response = await _api.get('/api/v1/admin/rbac/roles');
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
  }

  Future<List<Permission>> getPermissions() async {
    final response = await _api.get('/api/v1/admin/rbac/permissions');
    final payload = response.data;

    final modules = payload is Map<String, dynamic>
        ? payload['modules'] as List<dynamic>?
        : payload is Map
            ? (payload['modules'] as List<dynamic>?)
            : null;

    if (modules == null) {
      throw const FormatException('Permissions payload did not contain modules');
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
  }

  Future<Role> createRole({
    required String name,
    required String description,
    required List<int> permissionIds,
  }) async {
    final permissionSlugs = await _permissionSlugsFromIds(permissionIds);

    final response = await _api.post(
      '/api/v1/admin/rbac/roles',
      data: {
        'name': name,
        'description': description,
        'category': 'custom',
        'level': 0,
        'is_active': true,
        'permissions': permissionSlugs,
      },
    );
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

  List<String> getPermissionCategories() {
    return _cachedPermissions.map((p) => p.category).toSet().toList();
  }

  List<Permission> getPermissionsByCategory(String category) {
    return _cachedPermissions.where((p) => p.category == category).toList();
  }
}
