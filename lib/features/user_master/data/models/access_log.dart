class AccessLog {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String email;
  final String roleName;
  final String status;
  final String ipAddress;
  final String? deviceBrowser;
  final bool isSuccess;

  const AccessLog({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.email,
    required this.roleName,
    required this.status,
    required this.ipAddress,
    this.deviceBrowser,
    required this.isSuccess,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleName: json['role_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      ipAddress: json['ip_address']?.toString() ?? '',
      deviceBrowser: json['device_browser']?.toString(),
      isSuccess: json['is_success'] as bool? ?? true,
    );
  }
}
