import '../../../../core/api/api_client.dart';
import '../models/role.dart';

class RoleRepository {
  final ApiClient _api = ApiClient();
  
  // Cache permissions locally for synchronous utility methods
  List<Permission> _cachedPermissions = [];

  Future<List<Role>> getRoles() async {
    try {
      final response = await _api.get('/api/v1/admin/roles/');
      final data = response.data as List;
      return data.map((json) => Role.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching roles: $e");
      return [];
    }
  }

  Future<List<Permission>> getPermissions() async {
    try {
      final response = await _api.get('/api/v1/admin/roles/permissions');
      final data = response.data as List;
      _cachedPermissions = data.map((json) => Permission.fromJson(json)).toList();
      return _cachedPermissions;
    } catch (e) {
      print("Error fetching permissions: $e");
      return [];
    }
  }

  Future<Role> createRole({
    required String name,
    required String description,
    required List<int> permissionIds,
  }) async {
    final response = await _api.post('/api/v1/admin/roles/', data: {
      'name': name,
      'description': description,
      'category': 'custom',
      'level': 0,
      'is_active': true,
      'permission_ids': permissionIds,
    });
    return Role.fromJson(response.data);
  }

  Future<Role> updateRole(Role role, {List<int>? newPermissionIds}) async {
    final ids = newPermissionIds ?? 
                role.permissions.map((p) => p is int ? p : (p as Map<String, dynamic>)['id'] as int).toList();
    
    final response = await _api.put('/api/v1/admin/roles/${role.id}', data: {
      'name': role.name,
      'description': role.description,
      'is_active': role.isActive,
      'permission_ids': ids,
    });
    return Role.fromJson(response.data);
  }

  Future<void> togglePermission(Role role, int permissionId) async {
      final perms = role.permissions.map((p) => p is int ? p : (p as Map<String, dynamic>)['id'] as int).toList();
      if (perms.contains(permissionId)) {
        perms.remove(permissionId);
      } else {
        perms.add(permissionId);
      }
      await updateRole(role, newPermissionIds: perms);
  }

  /// Get permission categories for grouped display
  List<String> getPermissionCategories() {
    return _cachedPermissions.map((p) => p.category).toSet().toList();
  }

  List<Permission> getPermissionsByCategory(String category) {
    return _cachedPermissions.where((p) => p.category == category).toList();
  }
}
