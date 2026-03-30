enum UserStatus { active, inactive, suspended, pending }

class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String roleId;
  final String roleName;
  final String? assignedStationId;
  final String? assignedStationName;
  final String? profilePhotoUrl;
  final UserStatus status;
  final bool twoFactorEnabled;
  final String? notes;
  final DateTime lastLogin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.roleId,
    required this.roleName,
    this.assignedStationId,
    this.assignedStationName,
    this.profilePhotoUrl,
    required this.status,
    this.twoFactorEnabled = false,
    this.notes,
    required this.lastLogin,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      roleId: json['role_id'] as String,
      roleName: json['role_name'] as String,
      assignedStationId: json['assigned_station_id'] as String?,
      assignedStationName: json['assigned_station_name'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      status: UserStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?)?.toLowerCase(),
        orElse: () => UserStatus.pending,
      ),
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      notes: json['notes'] as String?,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login'] as String) : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role_id': roleId,
      'role_name': roleName,
      'assigned_station_id': assignedStationId,
      'assigned_station_name': assignedStationName,
      'profile_photo_url': profilePhotoUrl,
      'status': status.name,
      'two_factor_enabled': twoFactorEnabled,
      'notes': notes,
      'last_login': lastLogin.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
