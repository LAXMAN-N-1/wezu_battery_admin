class AuditLog {
  final String id;
  final int userId;
  final String userName;
  final String action; // 'create', 'update', 'delete', 'login', 'logout', 'suspend', 'reactivate', 'permission_change'
  final String module; // 'users', 'roles', 'kyc', 'settings', etc.
  final String details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final String? beforeValue;
  final String? afterValue;
  final Map<String, dynamic>? metadata;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.details,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.beforeValue,
    this.afterValue,
    this.metadata,
  });

  factory AuditLog.fromUserAuditJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['_id']?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      action: json['action'] ?? '',
      module: json['resource'] ?? 'users',
      details: '${json['event_type'] ?? ''} - ${json['status'] ?? ''}'.trim(),
      ipAddress: json['ip_address'],
      userAgent: null, // User audit schema doesn't have it explicitly in the snippet
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  factory AuditLog.fromRoleAuditJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Admin',
      action: json['action'] ?? '',
      module: json['resource_type'] ?? 'roles',
      details: json['details'] ?? '',
      ipAddress: json['ip_address'],
      userAgent: json['device_info'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  factory AuditLog.fromGenericJson(Map<String, dynamic> json) {
    return AuditLog(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'System',
      action: json['action'] ?? '',
      module: json['resource_type'] ?? json['resource'] ?? 'general',
      details: json['details'] ?? '',
      ipAddress: json['ip_address'],
      userAgent: json['device_info'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  String get actionLabel {
    switch (action.toLowerCase()) {
      case 'create': return 'Created';
      case 'update': return 'Updated';
      case 'delete': return 'Deleted';
      case 'login': return 'Logged In';
      case 'logout': return 'Logged Out';
      case 'suspend': return 'Suspended';
      case 'reactivate': return 'Reactivated';
      case 'permission_change': return 'Permission Changed';
      case 'kyc_approve': return 'KYC Approved';
      case 'kyc_reject': return 'KYC Rejected';
      default: return action;
    }
  }
}
