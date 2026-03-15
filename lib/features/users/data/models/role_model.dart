class Role {
  final int id;
  final String name;
  final String? description;
  final String category;
  final int level;
  final bool isSystemRole;
  final bool isActive;
  final int permissionCount;
  final int userCount;
  final List<Permission>? permissions;

  const Role({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.level,
    required this.isSystemRole,
    required this.isActive,
    this.permissionCount = 0,
    this.userCount = 0,
    this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    List<Permission>? perms;
    if (json['permissions'] != null) {
      perms = (json['permissions'] as List)
          .map((p) => Permission.fromJson(p))
          .toList();
    }

    return Role(
      id: json['id'] as int,
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'system',
      level: json['level'] ?? 0,
      isSystemRole: json['is_system_role'] ?? false,
      isActive: json['is_active'] ?? true,
      permissionCount: json['permission_count'] ?? 0,
      userCount: json['user_count'] ?? 0,
      permissions: perms,
    );
  }
}

class Permission {
  final int id;
  final String slug;
  final String? module;
  final String action;
  final String? description;

  const Permission({
    required this.id,
    required this.slug,
    this.module,
    required this.action,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as int,
      slug: json['slug'] ?? '',
      module: json['module'],
      action: json['action'] ?? '',
      description: json['description'],
    );
  }
}
