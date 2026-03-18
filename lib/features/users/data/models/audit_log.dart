class AuditLog {
  final int id;
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
  });

  String get actionLabel {
    switch (action) {
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
