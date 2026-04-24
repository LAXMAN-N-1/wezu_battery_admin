import 'dart:math';

import '../../../../core/api/api_client.dart';
import '../models/role_model.dart';

class RBACRepository {
  final ApiClient _api = ApiClient();
  static const String _base = '/api/v1/rbac';
  final Map<int, String> _permissionIdToSlug = {};

  Future<List<Role>> getRoles() async {
    final response = await _api.get('$_base/roles');
    final data = response.data;
    final roles = (data as List).map((r) => Role.fromJson(r)).toList();
    for (final role in roles) {
      final permissions = role.permissions ?? const <Permission>[];
      for (final permission in permissions) {
        _permissionIdToSlug[permission.id] = permission.slug;
      }
    }
    return roles;
  }

  Future<Role?> getRoleDetail(int roleId) async {
    final response = await _api.get('$_base/roles/$roleId');
    return Role.fromJson(response.data);
  }

  Future<bool> createRole({
    required String name,
    String? description,
    String category = 'system',
    int level = 0,
    List<int> permissionIds = const [],
  }) async {
    final permissionSlugs = await _permissionSlugsFromIds(permissionIds);

    await _api.post(
      '$_base/roles',
      data: {
        'name': name,
        'description': description,
        'category': category,
        'level': level,
        'permissions': permissionSlugs,
      },
    );
    return true;
  }

  Future<bool> updateRole(
    int roleId, {
    String? name,
    String? description,
    bool? isActive,
    List<int>? permissionIds,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isActive != null) data['is_active'] = isActive;
    if (permissionIds != null) {
      data['permissions'] = await _permissionSlugsFromIds(permissionIds);
    }
    await _api.put('$_base/roles/$roleId', data: data);
    return true;
  }

  Future<bool> deleteRole(int roleId) async {
    await _api.delete('$_base/roles/$roleId');
    return true;
  }

  Future<Map<String, List<Permission>>> getPermissions() async {
    final response = await _api.get('$_base/permissions');
    final data = response.data;

    if (data is List) {
      final permissions = data
          .whereType<Map>()
          .map((item) => Permission.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      for (final permission in permissions) {
        _permissionIdToSlug[permission.id] = permission.slug;
      }

      final grouped = <String, List<Permission>>{};
      for (final permission in permissions) {
        grouped
            .putIfAbsent(permission.module ?? 'general', () => [])
            .add(permission);
      }
      return grouped;
    }

    final modules = data is Map<String, dynamic>
        ? data['modules'] as List<dynamic>?
        : data is Map
        ? data['modules'] as List<dynamic>?
        : null;
    if (modules == null) {
      throw const FormatException(
        'Permissions payload did not contain modules',
      );
    }

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
  }

  Future<bool> assignRoleToUser(int userId, int roleId) async {
    await _api.post(
      '$_base/users/$userId/roles',
      data: {'role_id': roleId, 'notes': 'Assigned from RBAC panel'},
    );
    return true;
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
