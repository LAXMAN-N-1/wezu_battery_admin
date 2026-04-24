enum UserStatus { active, inactive, suspended, pending }

class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String roleId;
  final String roleName;
  final String rawRoleName;
  final int? dealerId;
  final List<int> stationIds;
  final List<int> warehouseIds;
  final String? assignedStationId;
  final String? assignedStationName;
  final String? profilePhotoUrl;
  final UserStatus status;
  final bool twoFactorEnabled;
  final String? notes;
  final DateTime? lastLogin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.roleId,
    required this.roleName,
    required this.rawRoleName,
    this.dealerId,
    this.stationIds = const [],
    this.warehouseIds = const [],
    this.assignedStationId,
    this.assignedStationName,
    this.profilePhotoUrl,
    required this.status,
    this.twoFactorEnabled = false,
    this.notes,
    required this.lastLogin,
    required this.createdAt,
  });

  static String _prettifyRoleName(String? rawRole) {
    final value = rawRole?.trim() ?? '';
    if (value.isEmpty) return 'Customer';
    return value
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      phone: (json['phone_number'] ?? json['phone']) as String?,
      roleId: (json['role_id'] ?? json['role_name'] ?? 'customer').toString(),
      rawRoleName: (json['role_name'] ?? json['role'] ?? 'customer').toString(),
      roleName: _prettifyRoleName(
        (json['role'] ?? json['role_name'] ?? 'Customer')?.toString(),
      ),
      dealerId: (json['dealer_id'] as num?)?.toInt(),
      stationIds: ((json['station_ids'] as List?) ?? const <dynamic>[])
          .whereType<num>()
          .map((item) => item.toInt())
          .toList(),
      warehouseIds: ((json['warehouse_ids'] as List?) ?? const <dynamic>[])
          .whereType<num>()
          .map((item) => item.toInt())
          .toList(),
      assignedStationId: json['assigned_station_id']?.toString(),
      assignedStationName: json['assigned_station_name'] as String?,
      profilePhotoUrl:
          (json['profile_picture'] ?? json['profile_photo_url']) as String?,
      status: UserStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?)?.toLowerCase(),
        orElse: () => UserStatus.pending,
      ),
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      notes:
          (json['notes'] ??
                  json['suspension_reason'] ??
                  json['deletion_reason'])
              as String?,
      lastLogin: json['last_login_at'] != null || json['last_login'] != null
          ? DateTime.parse(
              (json['last_login_at'] ?? json['last_login']) as String,
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role_id': roleId,
      'role_name': rawRoleName,
      'dealer_id': dealerId,
      'station_ids': stationIds,
      'warehouse_ids': warehouseIds,
      'assigned_station_id': assignedStationId,
      'assigned_station_name': assignedStationName,
      'profile_photo_url': profilePhotoUrl,
      'status': status.name,
      'two_factor_enabled': twoFactorEnabled,
      'notes': notes,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
