class UserSession {
  final int id;
  final String deviceType;
  final String deviceName;
  final String ipAddress;
  final DateTime lastActiveAt;
  final bool isCurrent;
  final bool isActive;
  final DateTime createdAt;

  UserSession({
    required this.id,
    required this.deviceType,
    required this.deviceName,
    required this.ipAddress,
    required this.lastActiveAt,
    required this.isCurrent,
    required this.isActive,
    required this.createdAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as int,
      deviceType: json['device_type'] ?? 'unknown',
      deviceName: json['device_name'] ?? 'Unknown Device',
      ipAddress: json['ip_address'] ?? '0.0.0.0',
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at']) : DateTime.now(),
      isCurrent: json['is_current'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_type': deviceType,
      'device_name': deviceName,
      'ip_address': ipAddress,
      'last_active_at': lastActiveAt.toIso8601String(),
      'is_current': isCurrent,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
