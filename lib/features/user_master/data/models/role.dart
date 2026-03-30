enum PermissionLevel { full, view, limited, selfOnly, noAccess }

class PermissionMatrix {
  final Map<String, PermissionLevel> modules;

  const PermissionMatrix({required this.modules});

  factory PermissionMatrix.fromJson(Map<String, dynamic> json) {
    final modules = <String, PermissionLevel>{};
    json.forEach((key, value) {
      modules[key] = PermissionLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (value as String).toLowerCase().replaceAll('_', ''),
        orElse: () => PermissionLevel.noAccess,
      );
    });
    return PermissionMatrix(modules: modules);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    modules.forEach((key, value) {
      data[key] = value.name;
    });
    return data;
  }
}

class Role {
  final String id;
  final String name;
  final String description;
  final bool isSystemRole;
  final int userCount;
  final PermissionMatrix permissions;
  final DateTime createdAt;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    this.isSystemRole = false,
    this.userCount = 0,
    required this.permissions,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    // Handle both Map (legacy/mock) and List (real backend) for permissions
    final permissionsData = json['permissions'];
    final Map<String, PermissionLevel> modulesMap = {};

    if (permissionsData is List) {
      for (var p in permissionsData) {
        if (p is Map<String, dynamic>) {
          final module = p['module'] as String? ?? 'Other';
          final action = p['action'] as String? ?? 'view';
          
          // Simple logic: if 'manage' or 'all' or 'create' -> full, else view
          if (['all', 'manage', 'delete', 'create'].contains(action.toLowerCase())) {
            modulesMap[module] = PermissionLevel.full;
          } else {
            modulesMap[module] = PermissionLevel.view;
          }
        }
      }
    } else if (permissionsData is Map<String, dynamic>) {
      permissionsData.forEach((key, value) {
        modulesMap[key] = PermissionLevel.values.firstWhere(
          (e) => e.name.toLowerCase() == (value as String).toLowerCase().replaceAll('_', ''),
          orElse: () => PermissionLevel.noAccess,
        );
      });
    }

    return Role(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isSystemRole: json['is_system_role'] as bool? ?? false,
      userCount: json['user_count'] as int? ?? 0,
      permissions: PermissionMatrix(modules: modulesMap),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_system_role': isSystemRole,
      'user_count': userCount,
      'permissions': permissions.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
