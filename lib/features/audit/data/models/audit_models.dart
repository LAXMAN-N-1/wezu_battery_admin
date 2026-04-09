class AuditLogItem {
  final int id;
  final int? userId;
  final String userName;
  final String userEmail;
  final String userAvatar;
  final String userRole;
  final String action;
  final String module;
  final String resourceType;
  final String? resourceId;
  final String details;
  final String? ipAddress;
  final String? userAgent;
  final String? browser;
  final String? os;
  final String? city;
  final String? countryFlag;
  final String timestamp;
  final String? oldValue;
  final String? newValue;
  final String severity;
  final String status; // success | failed
  final bool isSuspicious;

  AuditLogItem({
    required this.id,
    this.userId,
    this.userName = 'System',
    this.userEmail = '',
    this.userAvatar = '',
    this.userRole = 'Admin',
    required this.action,
    this.module = 'System',
    required this.resourceType,
    this.resourceId,
    required this.details,
    this.ipAddress,
    this.userAgent,
    this.browser,
    this.os,
    this.city,
    this.countryFlag,
    required this.timestamp,
    this.oldValue,
    this.newValue,
    this.severity = 'info',
    this.status = 'success',
    this.isSuspicious = false,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) => AuditLogItem(
    id: (json['id'] is int) ? json['id'] : 0,
    userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
    userName: json['user_name']?.toString() ?? 'System',
    userEmail: json['user_email']?.toString() ?? '',
    userAvatar: json['user_avatar']?.toString() ?? '',
    userRole: json['user_role']?.toString() ?? 'Admin',
    action: json['action']?.toString() ?? '',
    module: json['module']?.toString() ?? 'System',
    resourceType: json['resource_type']?.toString() ?? '',
    resourceId: json['resource_id']?.toString(),
    details: json['details']?.toString() ?? '',
    ipAddress: json['ip_address']?.toString(),
    userAgent: json['user_agent']?.toString(),
    browser: json['browser']?.toString(),
    os: json['os']?.toString(),
    city: json['city']?.toString(),
    countryFlag: json['country_flag']?.toString(),
    timestamp: json['timestamp']?.toString() ?? '',
    oldValue: json['old_value']?.toString(),
    newValue: json['new_value']?.toString(),
    severity: json['severity']?.toString() ?? 'info',
    status: json['status']?.toString() ?? 'success',
    isSuspicious: json['is_suspicious'] == true,
  );

  AuditLogItem copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userEmail,
    String? userAvatar,
    String? userRole,
    String? action,
    String? module,
    String? resourceType,
    String? resourceId,
    String? details,
    String? ipAddress,
    String? userAgent,
    String? browser,
    String? os,
    String? city,
    String? countryFlag,
    String? timestamp,
    String? oldValue,
    String? newValue,
    String? severity,
    String? status,
    bool? isSuspicious,
  }) {
    return AuditLogItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
      userRole: userRole ?? this.userRole,
      action: action ?? this.action,
      module: module ?? this.module,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      details: details ?? this.details,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      browser: browser ?? this.browser,
      os: os ?? this.os,
      city: city ?? this.city,
      countryFlag: countryFlag ?? this.countryFlag,
      timestamp: timestamp ?? this.timestamp,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      isSuspicious: isSuspicious ?? this.isSuspicious,
    );
  }
}

class SecurityEventItem {
  final int id;
  final String eventType;
  final String severity;
  final String details;
  final String? sourceIp;
  final String? country;
  final String? countryFlag;
  final double? latitude;
  final double? longitude;
  final int? userId;
  final String timestamp;
  final bool isResolved;
  final String? payload; // For terminal raw view

  SecurityEventItem({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.details,
    this.sourceIp,
    this.country,
    this.countryFlag,
    this.latitude,
    this.longitude,
    this.userId,
    required this.timestamp,
    required this.isResolved,
    this.payload,
  });

  factory SecurityEventItem.fromJson(Map<String, dynamic> json) => SecurityEventItem(
    id: (json['id'] is int) ? json['id'] : 0,
    eventType: json['event_type']?.toString() ?? '',
    severity: json['severity']?.toString() ?? '',
    details: json['details']?.toString() ?? '',
    sourceIp: json['source_ip']?.toString(),
    country: json['country']?.toString(),
    countryFlag: json['country_flag']?.toString(),
    latitude: json['latitude'] is double ? json['latitude'] : double.tryParse(json['latitude']?.toString() ?? ''),
    longitude: json['longitude'] is double ? json['longitude'] : double.tryParse(json['longitude']?.toString() ?? ''),
    userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
    timestamp: json['timestamp']?.toString() ?? '',
    isResolved: json['is_resolved'] == true,
    payload: json['payload']?.toString(),
  );
}

class FraudAlertItem {
  final String id;
  final int userId;
  final String userName;
  final String userAvatar;
  final String userEmail;
  final String alertType;
  final int riskScore;
  final String timestamp;
  final String status; // Open | Investigation | Resolved
  final String details;

  FraudAlertItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userEmail,
    required this.alertType,
    required this.riskScore,
    required this.timestamp,
    required this.status,
    required this.details,
  });

  factory FraudAlertItem.fromJson(Map<String, dynamic> json) => FraudAlertItem(
    id: json['id']?.toString() ?? '',
    userId: json['user_id'] is int ? json['user_id'] : 0,
    userName: json['user_name']?.toString() ?? '',
    userAvatar: json['user_avatar']?.toString() ?? '',
    userEmail: json['user_email']?.toString() ?? '',
    alertType: json['alert_type']?.toString() ?? '',
    riskScore: json['risk_score'] is int ? json['risk_score'] : 0,
    timestamp: json['timestamp']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Open',
    details: json['details']?.toString() ?? '',
  );
}

class AuditDashboardStats {
  final int totalEventsToday;
  final int adminActionsToday;
  final int infoEventsToday;
  final int warningEventsToday;
  final int criticalEventsToday;
  final int failedLoginsToday;
  final List<ChartPoint> activityPoints;
  final Map<String, double> categoryDistribution;
  final List<SecurityEventItem> recentCriticalEvents;
  final List<LocationStat> topLocations;

  AuditDashboardStats({
    required this.totalEventsToday,
    required this.adminActionsToday,
    required this.infoEventsToday,
    required this.warningEventsToday,
    required this.criticalEventsToday,
    required this.failedLoginsToday,
    required this.activityPoints,
    required this.categoryDistribution,
    required this.recentCriticalEvents,
    this.topLocations = const [],
  });
}

class LocationStat {
  final String country;
  final String attempts;
  final String successfulAttempts;
  final String successRate;

  LocationStat({
    required this.country,
    required this.attempts,
    required this.successfulAttempts,
    required this.successRate,
  });
}

class ChartPoint {
  final String time;
  final int apiRequests;
  final int failedLogins;

  ChartPoint({required this.time, required this.apiRequests, required this.failedLogins});
}
