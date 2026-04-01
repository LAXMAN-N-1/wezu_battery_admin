import '../../../../core/api/api_client.dart';
import '../models/role_model.dart';
import 'dart:math';

class RBACRepository {
  final ApiClient _api = ApiClient();
  final Map<int, String> _permissionIdToSlug = {};

  Future<List<Role>> getRoles() async {
    try {
      final response = await _api.get('/api/v1/admin/rbac/roles');
      final data = response.data;
      final roles = (data as List).map((r) => Role.fromJson(r)).toList();
      for (final role in roles) {
        final permissions = role.permissions ?? const <Permission>[];
        for (final permission in permissions) {
          _permissionIdToSlug[permission.id] = permission.slug;
        }
      }
      return roles;
    } catch (e) {
      return [];
    }
  }

  Future<Role?> getRoleDetail(int roleId) async {
    try {
      final response = await _api.get('/api/v1/admin/rbac/roles/$roleId');
      return Role.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createRole({
    required String name,
    String? description,
    String category = 'system',
    int level = 0,
    List<int> permissionIds = const [],
  }) async {
    try {
      final permissionSlugs = await _permissionSlugsFromIds(permissionIds);

      await _api.post(
        '/api/v1/admin/rbac/roles',
        data: {
          'name': name,
          'description': description,
          'category': category,
          'level': level,
          'permissions': permissionSlugs,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRole(
    int roleId, {
    String? name,
    String? description,
    bool? isActive,
    List<int>? permissionIds,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (isActive != null) data['is_active'] = isActive;
      if (permissionIds != null) {
        data['permissions'] = await _permissionSlugsFromIds(permissionIds);
      }
      await _api.put('/api/v1/admin/rbac/roles/$roleId', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRole(int roleId) async {
    try {
      await _api.delete('/api/v1/admin/rbac/roles/$roleId');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, List<Permission>>> getPermissions() async {
    try {
      final response = await _api.get('/api/v1/admin/rbac/permissions');
      final data = response.data;
      final modules = data is Map<String, dynamic>
          ? data['modules'] as List<dynamic>?
          : data is Map
          ? data['modules'] as List<dynamic>?
          : null;
      if (modules == null) return {};

      final permsList = <Permission>[];
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

          permsList.add(
            Permission(
              id: id,
              slug: slug,
              module: permissionMap['resource']?.toString() ?? moduleName,
              action: permissionMap['action']?.toString() ?? '',
              description: permissionMap['description']?.toString(),
            ),
          );
          _permissionIdToSlug[id] = slug;
        }
      }

      final grouped = <String, List<Permission>>{};
      for (var p in permsList) {
        grouped.putIfAbsent(p.module ?? 'general', () => []).add(p);
      }
      return grouped;
    } catch (e) {
      return {};
    }
  }

  Future<bool> assignRoleToUser(int userId, int roleId) async {
    try {
      await _api.post(
        '/api/v1/admin/rbac/users/$userId/roles',
        data: {'role_id': roleId, 'notes': 'Assigned from RBAC panel'},
      );
      return true;
    } catch (e) {
      return false;
    }
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
}
