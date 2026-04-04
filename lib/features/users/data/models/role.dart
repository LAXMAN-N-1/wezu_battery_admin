class Role {
  final int id;
  final String name;
  final String description;
  final String category;
  final int level;
  final bool isActive;
  final List<dynamic> permissions; // Backend returns List of Permission objects or IDs
  final bool isSystem;
  final int? parentRoleId;
  final bool isSystemRole;
  final String? icon;
  final String? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int permissionCount;
  final int userCount;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'custom',
    this.level = 0,
    this.isActive = true,
    required this.permissions,
    this.isSystem = false,
    this.parentRoleId,
    this.isSystemRole = false,
    this.icon,
    this.color,
    this.createdAt,
    this.updatedAt,
    this.permissionCount = 0,
    this.userCount = 0,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] ?? '',
      category: json['category'] ?? 'custom',
      level: json['level'] ?? 0,
      isActive: json['is_active'] ?? true,
      permissions: json['permissions'] ?? [],
      isSystem: json['category'] == 'system' || (json['is_system_role'] ?? false),
      parentRoleId: json['parent_role_id'],
      isSystemRole: json['is_system_role'] ?? false,
      icon: json['icon'],
      color: json['color'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      permissionCount: json['permission_count'] ?? 0,
      userCount: json['user_count'] ?? 0,
    );
  }

  Role copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    int? level,
    bool? isActive,
    List<dynamic>? permissions,
    bool? isSystem,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      isSystem: isSystem ?? this.isSystem,
      parentRoleId: parentRoleId ?? this.parentRoleId,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permissionCount: permissionCount ?? this.permissionCount,
      userCount: userCount ?? this.userCount,
    );
  }
}

class Permission {
  final int id;
  final String slug;
  final String module;
  final String action;
  final String description;
  final String scope;

  const Permission({
    required this.id,
    required this.slug,
    required this.module,
    required this.action,
    required this.description,
    this.scope = 'all',
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as int,
      slug: json['slug'] as String,
      module: json['module'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      scope: json['scope'] ?? 'all',
    );
  }

  // To maintain compatibility with existing UI
  String get name => slug;
  String get category => module;
}
