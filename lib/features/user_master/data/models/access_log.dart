class AccessLog {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String roleName;
  final String actionType;
  final String moduleAffected;
  final String ipAddress;
  final String? deviceBrowser;
  final bool isSuccess;

  const AccessLog({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.roleName,
    required this.actionType,
    required this.moduleAffected,
    required this.ipAddress,
    this.deviceBrowser,
    required this.isSuccess,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      roleName: json['role_name'] as String,
      actionType: json['action_type'] as String,
      moduleAffected: json['module_affected'] as String,
      ipAddress: json['ip_address'] as String,
      deviceBrowser: json['device_browser'] as String?,
      isSuccess: json['is_success'] as bool? ?? true,
    );
  }
}
