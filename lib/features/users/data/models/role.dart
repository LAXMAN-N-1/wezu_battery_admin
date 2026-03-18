class Role {
  final int id;
  final String name;
  final String description;
  final String category;
  final int level;
  final bool isActive;
  final List<dynamic> permissions; // Backend returns List of Permission objects or IDs
  final bool isSystem;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'custom',
    this.level = 0,
    this.isActive = true,
    required this.permissions,
    this.isSystem = false,
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
      isSystem: json['category'] == 'system',
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
    );
  }
}

class Permission {
  final int id;
  final String slug;
  final String module;
  final String action;
  final String description;

  const Permission({
    required this.id,
    required this.slug,
    required this.module,
    required this.action,
    required this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as int,
      slug: json['slug'] as String,
      module: json['module'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
    );
  }

  // To maintain compatibility with existing UI
  String get name => slug;
  String get category => module;
}
