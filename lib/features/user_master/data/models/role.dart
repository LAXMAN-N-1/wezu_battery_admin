enum PermissionLevel { full, view, limited, selfOnly, noAccess }

class PermissionMatrix {
  final Map<String, PermissionLevel> modules;

  const PermissionMatrix({required this.modules});

  factory PermissionMatrix.fromJson(Map<String, dynamic> json) {
    final modules = <String, PermissionLevel>{};
    json.forEach((key, value) {
      modules[key] = PermissionLevel.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (value as String).toLowerCase().replaceAll('_', ''),
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
  final String category;
  final int level;
  final String? userType;
  final bool requiresDealerProfile;
  final bool requiresDealerId;
  final bool requiresWarehouseIds;
  final bool isSystemRole;
  final int userCount;
  final PermissionMatrix permissions;
  final DateTime createdAt;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'system',
    this.level = 0,
    this.userType,
    this.requiresDealerProfile = false,
    this.requiresDealerId = false,
    this.requiresWarehouseIds = false,
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

          const fullActions = {
            'all', 'manage', 'delete', 'create', 'update',
            'assign', 'approve', 'export', 'override',
          };
          if (fullActions.contains(action.toLowerCase())) {
            modulesMap[module] = PermissionLevel.full;
          } else if (modulesMap[module] != PermissionLevel.full) {
            modulesMap[module] = PermissionLevel.view;
          }
        }
      }
    } else if (permissionsData is Map<String, dynamic>) {
      permissionsData.forEach((key, value) {
        modulesMap[key] = PermissionLevel.values.firstWhere(
          (e) =>
              e.name.toLowerCase() ==
              (value as String).toLowerCase().replaceAll('_', ''),
          orElse: () => PermissionLevel.noAccess,
        );
      });
    }

    return Role(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category']?.toString() ?? 'system',
      level: json['level'] as int? ?? 0,
      userType: json['user_type']?.toString(),
      requiresDealerProfile: json['requires_dealer_profile'] as bool? ?? false,
      requiresDealerId: json['requires_dealer_id'] as bool? ?? false,
      requiresWarehouseIds: json['requires_warehouse_ids'] as bool? ?? false,
      isSystemRole: json['is_system_role'] as bool? ?? false,
      userCount: json['user_count'] as int? ?? 0,
      permissions: PermissionMatrix(modules: modulesMap),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'level': level,
      'user_type': userType,
      'requires_dealer_profile': requiresDealerProfile,
      'requires_dealer_id': requiresDealerId,
      'requires_warehouse_ids': requiresWarehouseIds,
      'is_system_role': isSystemRole,
      'user_count': userCount,
      'permissions': permissions.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
