import '../../../../core/api/api_client.dart';
import '../models/role_model.dart';

class RBACRepository {
  final ApiClient _api = ApiClient();

  Future<List<Role>> getRoles() async {
    try {
      final response = await _api.get('/api/v1/admin/rbac/roles');
      final data = response.data;
      return (data['roles'] as List).map((r) => Role.fromJson(r)).toList();
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
      await _api.post('/api/v1/admin/rbac/roles', data: {
        'name': name,
        'description': description,
        'category': category,
        'level': level,
        'permission_ids': permissionIds,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRole(int roleId, {
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
      if (permissionIds != null) data['permission_ids'] = permissionIds;
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
      final permsMap = response.data['permissions'] as Map<String, dynamic>;
      return permsMap.map((module, perms) {
        return MapEntry(
          module,
          (perms as List).map((p) => Permission.fromJson(p)).toList(),
        );
      });
    } catch (e) {
      return {};
    }
  }

  Future<bool> assignRoleToUser(int userId, int roleId) async {
    try {
      await _api.post('/api/v1/admin/rbac/users/$userId/assign-role', data: {
        'role_id': roleId,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
