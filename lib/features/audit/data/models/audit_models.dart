class AuditLogItem {
  final int id;
  final int? userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String action;
  final String module;
  final String resourceType;
  final String? resourceId;
  final String details;
  final String? ipAddress;
  final String? location;
  final String? device;
  final String? browser;
  final String severity; // Info, Warning, Critical
  final String status; // Success, Failed
  final String timestamp;
  final String? oldValue;
  final String? newValue;
  final String severity;
  final String status; // success | failed
  final bool isSuspicious;

  AuditLogItem({
    required this.id, this.userId, this.userName = 'System', this.userEmail = '', this.userAvatar,
    required this.action, required this.resourceType, this.resourceId,
    required this.details, this.ipAddress, this.location, this.device, this.browser,
    this.severity = 'Info', this.status = 'Success', required this.timestamp,
    this.oldValue, this.newValue,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) => AuditLogItem(
    id: (json['id'] is int) ? json['id'] : 0,
    userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
    userName: json['user_name']?.toString() ?? 'System',
    userEmail: json['user_email']?.toString() ?? '',
    userAvatar: json['user_avatar']?.toString(),
    action: json['action']?.toString() ?? '',
    module: json['module']?.toString() ?? 'System',
    resourceType: json['resource_type']?.toString() ?? '',
    resourceId: json['resource_id']?.toString(),
    details: json['details']?.toString() ?? '',
    ipAddress: json['ip_address']?.toString(),
    location: json['location']?.toString(),
    device: json['device']?.toString(),
    browser: json['browser']?.toString(),
    severity: json['severity']?.toString() ?? 'Info',
    status: json['status']?.toString() ?? 'Success',
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
  final String? payload;

  SecurityEventItem({
    required this.id, required this.eventType, required this.severity,
    required this.details, this.sourceIp, this.userId, required this.timestamp,
    required this.isResolved, this.payload,
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

class FraudAlert {
  final String id;
  final int userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String alertType; 
  final double riskScore;
  final String detectedAt;
  final String status; // Open, Under Investigation, Resolved, False Positive
  final List<InvestigationNote> notes;

  FraudAlert({
    required this.id, required this.userId, required this.userName, required this.userEmail,
    this.userAvatar, required this.alertType, required this.riskScore,
    required this.detectedAt, required this.status, this.notes = const [],
  });

  factory FraudAlert.fromJson(Map<String, dynamic> json) => FraudAlert(
    id: json['id']?.toString() ?? '',
    userId: (json['user_id'] is int) ? json['user_id'] : 0,
    userName: json['user_name']?.toString() ?? '',
    userEmail: json['user_email']?.toString() ?? '',
    userAvatar: json['user_avatar']?.toString(),
    alertType: json['alert_type']?.toString() ?? '',
    riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
    detectedAt: json['detected_at']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Open',
    notes: (json['notes'] as List?)?.map((e) => InvestigationNote.fromJson(e)).toList() ?? [],
  );
}

class InvestigationNote {
  final String author;
  final String timestamp;
  final String content;

  InvestigationNote({required this.author, required this.timestamp, required this.content});

  factory InvestigationNote.fromJson(Map<String, dynamic> json) => InvestigationNote(
    author: json['author']?.toString() ?? '',
    timestamp: json['timestamp']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
  );
}

class SecuritySettings {
  final PasswordPolicy passwordPolicy;
  final TwoFactorAuthConfig twoFactor;
  final SessionMgmtConfig sessionMgmt;
  final IpWhitelistConfig ipWhitelist;
  final LoginControlsConfig loginControls;

  SecuritySettings({
    required this.passwordPolicy, required this.twoFactor,
    required this.sessionMgmt, required this.ipWhitelist,
    required this.loginControls,
  });

  SecuritySettings copyWith({
    PasswordPolicy? passwordPolicy,
    TwoFactorAuthConfig? twoFactor,
    SessionMgmtConfig? sessionMgmt,
    IpWhitelistConfig? ipWhitelist,
    LoginControlsConfig? loginControls,
  }) => SecuritySettings(
    passwordPolicy: passwordPolicy ?? this.passwordPolicy,
    twoFactor: twoFactor ?? this.twoFactor,
    sessionMgmt: sessionMgmt ?? this.sessionMgmt,
    ipWhitelist: ipWhitelist ?? this.ipWhitelist,
    loginControls: loginControls ?? this.loginControls,
  );

  factory SecuritySettings.defaultSettings() => SecuritySettings(
    passwordPolicy: PasswordPolicy(minLength: 8, requireUppercase: true, requireNumbers: true, requireSpecial: true, expiryDays: 90),
    twoFactor: TwoFactorAuthConfig(enabled: true, enforceSuperAdmin: true, enforceAllAdmin: false),
    sessionMgmt: SessionMgmtConfig(timeoutMinutes: 30, maxConcurrentSessions: 1, notifyNewSession: true),
    ipWhitelist: IpWhitelistConfig(enabled: false, whitelistedIps: ['192.168.1.1', '10.0.0.1']),
    loginControls: LoginControlsConfig(maxFailedAttempts: 5, lockoutDurationMinutes: 30, emailOnLockout: true),
  );

  Map<String, dynamic> toJson() => {
    'password_policy': passwordPolicy.toJson(),
    'two_factor': twoFactor.toJson(),
    'session_mgmt': sessionMgmt.toJson(),
    'ip_whitelist': ipWhitelist.toJson(),
    'login_controls': loginControls.toJson(),
  };

  factory SecuritySettings.fromJson(Map<String, dynamic> json) => SecuritySettings(
    passwordPolicy: PasswordPolicy.fromJson(json['password_policy'] ?? {}),
    twoFactor: TwoFactorAuthConfig.fromJson(json['two_factor'] ?? {}),
    sessionMgmt: SessionMgmtConfig.fromJson(json['session_mgmt'] ?? {}),
    ipWhitelist: IpWhitelistConfig.fromJson(json['ip_whitelist'] ?? {}),
    loginControls: LoginControlsConfig.fromJson(json['login_controls'] ?? {}),
  );
}

class PasswordPolicy {
  final int minLength;
  final bool requireUppercase;
  final bool requireNumbers;
  final bool requireSpecial;
  final int expiryDays;

  PasswordPolicy({required this.minLength, required this.requireUppercase, required this.requireNumbers, required this.requireSpecial, required this.expiryDays});

  PasswordPolicy copyWith({int? minLength, bool? requireUppercase, bool? requireNumbers, bool? requireSpecial, int? expiryDays}) => PasswordPolicy(
    minLength: minLength ?? this.minLength,
    requireUppercase: requireUppercase ?? this.requireUppercase,
    requireNumbers: requireNumbers ?? this.requireNumbers,
    requireSpecial: requireSpecial ?? this.requireSpecial,
    expiryDays: expiryDays ?? this.expiryDays,
  );

  Map<String, dynamic> toJson() => {'min_length': minLength, 'require_uppercase': requireUppercase, 'require_numbers': requireNumbers, 'require_special': requireSpecial, 'expiry_days': expiryDays};
  factory PasswordPolicy.fromJson(Map<String, dynamic> json) => PasswordPolicy(
    minLength: json['min_length'] ?? 8,
    requireUppercase: json['require_uppercase'] ?? true,
    requireNumbers: json['require_numbers'] ?? true,
    requireSpecial: json['require_special'] ?? true,
    expiryDays: json['expiry_days'] ?? 90,
  );
}

class TwoFactorAuthConfig {
  final bool enabled;
  final bool enforceSuperAdmin;
  final bool enforceAllAdmin;
  final bool allowSMS;
  final bool allowEmail;
  final bool allowTOTP;

  TwoFactorAuthConfig({
    required this.enabled, 
    required this.enforceSuperAdmin, 
    required this.enforceAllAdmin,
    this.allowSMS = false,
    this.allowEmail = false,
    this.allowTOTP = false,
  });

  TwoFactorAuthConfig copyWith({
    bool? enabled, 
    bool? enforceSuperAdmin, 
    bool? enforceAllAdmin,
    bool? allowSMS,
    bool? allowEmail,
    bool? allowTOTP,
  }) => TwoFactorAuthConfig(
    enabled: enabled ?? this.enabled,
    enforceSuperAdmin: enforceSuperAdmin ?? this.enforceSuperAdmin,
    enforceAllAdmin: enforceAllAdmin ?? this.enforceAllAdmin,
    allowSMS: allowSMS ?? this.allowSMS,
    allowEmail: allowEmail ?? this.allowEmail,
    allowTOTP: allowTOTP ?? this.allowTOTP,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled, 
    'enforce_super_admin': enforceSuperAdmin, 
    'enforce_all_admin': enforceAllAdmin,
    'allow_sms': allowSMS,
    'allow_email': allowEmail,
    'allow_totp': allowTOTP,
  };

  factory TwoFactorAuthConfig.fromJson(Map<String, dynamic> json) => TwoFactorAuthConfig(
    enabled: json['enabled'] ?? false, 
    enforceSuperAdmin: json['enforce_super_admin'] ?? true, 
    enforceAllAdmin: json['enforce_all_admin'] ?? false,
    allowSMS: json['allow_sms'] ?? false,
    allowEmail: json['allow_email'] ?? false,
    allowTOTP: json['allow_totp'] ?? false,
  );
}

class SessionMgmtConfig {
  final int timeoutMinutes;
  final int maxConcurrentSessions;
  final bool notifyNewSession;

  SessionMgmtConfig({required this.timeoutMinutes, required this.maxConcurrentSessions, required this.notifyNewSession});

  SessionMgmtConfig copyWith({int? timeoutMinutes, int? maxConcurrentSessions, bool? notifyNewSession}) => SessionMgmtConfig(
    timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
    maxConcurrentSessions: maxConcurrentSessions ?? this.maxConcurrentSessions,
    notifyNewSession: notifyNewSession ?? this.notifyNewSession,
  );

  Map<String, dynamic> toJson() => {'timeout_minutes': timeoutMinutes, 'max_concurrent_sessions': maxConcurrentSessions, 'notify_new_session': notifyNewSession};
  factory SessionMgmtConfig.fromJson(Map<String, dynamic> json) => SessionMgmtConfig(
    timeoutMinutes: json['timeout_minutes'] ?? 30,
    maxConcurrentSessions: json['max_concurrent_sessions'] ?? 1,
    notifyNewSession: json['notify_new_session'] ?? true,
  );
}

class IpWhitelistConfig {
  final bool enabled;
  final List<String> whitelistedIps;

  IpWhitelistConfig({required this.enabled, required this.whitelistedIps});

  IpWhitelistConfig copyWith({bool? enabled, List<String>? whitelistedIps}) => IpWhitelistConfig(enabled: enabled ?? this.enabled, whitelistedIps: whitelistedIps ?? this.whitelistedIps);

  Map<String, dynamic> toJson() => {'enabled': enabled, 'whitelisted_ips': whitelistedIps};
  factory IpWhitelistConfig.fromJson(Map<String, dynamic> json) => IpWhitelistConfig(enabled: json['enabled'] ?? false, whitelistedIps: List<String>.from(json['whitelisted_ips'] ?? []));
}

class LoginControlsConfig {
  final int maxFailedAttempts;
  final int lockoutDurationMinutes;
  final bool emailOnLockout;

  LoginControlsConfig({required this.maxFailedAttempts, required this.lockoutDurationMinutes, required this.emailOnLockout});

  LoginControlsConfig copyWith({int? maxFailedAttempts, int? lockoutDurationMinutes, bool? emailOnLockout}) => LoginControlsConfig(
    maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
    lockoutDurationMinutes: lockoutDurationMinutes ?? this.lockoutDurationMinutes,
    emailOnLockout: emailOnLockout ?? this.emailOnLockout,
  );

  Map<String, dynamic> toJson() => {'max_failed_attempts': maxFailedAttempts, 'lockout_duration_minutes': lockoutDurationMinutes, 'email_on_lockout': emailOnLockout};
  factory LoginControlsConfig.fromJson(Map<String, dynamic> json) => LoginControlsConfig(
    maxFailedAttempts: json['max_failed_attempts'] ?? 5,
    lockoutDurationMinutes: json['lockout_duration_minutes'] ?? 30,
    emailOnLockout: json['email_on_lockout'] ?? true,
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
