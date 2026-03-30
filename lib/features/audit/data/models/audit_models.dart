class AuditLogItem {
  final int id;
  final int? userId;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String details;
  final String? ipAddress;
  final String? userAgent;
  final String timestamp;
  final String? oldValue;
  final String? newValue;

  AuditLogItem({
    required this.id, this.userId, required this.action, required this.resourceType,
    this.resourceId, required this.details, this.ipAddress, this.userAgent,
    required this.timestamp, this.oldValue, this.newValue,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) => AuditLogItem(
    id: (json['id'] is int) ? json['id'] : 0,
    userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
    action: json['action']?.toString() ?? '',
    resourceType: json['resource_type']?.toString() ?? '',
    resourceId: json['resource_id']?.toString(),
    details: json['details']?.toString() ?? '',
    ipAddress: json['ip_address']?.toString(),
    userAgent: json['user_agent']?.toString(),
    timestamp: json['timestamp']?.toString() ?? '',
    oldValue: json['old_value']?.toString(),
    newValue: json['new_value']?.toString(),
  );
}

class SecurityEventItem {
  final int id;
  final String eventType;
  final String severity;
  final String details;
  final String? sourceIp;
  final int? userId;
  final String timestamp;
  final bool isResolved;

  SecurityEventItem({
    required this.id, required this.eventType, required this.severity,
    required this.details, this.sourceIp, this.userId, required this.timestamp,
    required this.isResolved,
  });

  factory SecurityEventItem.fromJson(Map<String, dynamic> json) => SecurityEventItem(
    id: (json['id'] is int) ? json['id'] : 0,
    eventType: json['event_type']?.toString() ?? '',
    severity: json['severity']?.toString() ?? '',
    details: json['details']?.toString() ?? '',
    sourceIp: json['source_ip']?.toString(),
    userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
    timestamp: json['timestamp']?.toString() ?? '',
    isResolved: json['is_resolved'] == true,
  );
}
