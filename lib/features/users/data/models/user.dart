class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // 'admin', 'customer', 'driver', 'dealer', 'supervisor', 'support'
  final String kycStatus; // 'verified', 'pending', 'rejected', 'not_submitted'
  final bool isActive;
  final DateTime joinedAt;
  final DateTime lastActive;
  final String? profileImageUrl;
  final String? address;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? suspendedUntil;
  final String? invitedBy;
  final String? lastLoginIp;
  final int loginCount;
  final double totalSpent;
  final int fraudRiskScore; // 0-100
  final bool forcePasswordReset;

  int get riskScore => fraudRiskScore;
  
  String get riskLevel {
    if (riskScore >= 80) return 'critical';
    if (riskScore >= 50) return 'high';
    if (riskScore >= 20) return 'medium';
    return 'low';
  }

  String get suspensionStatus {
    if (isActive) return 'active';
    if (suspensionReason != null) return 'suspended';
    return 'inactive';
  }

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.kycStatus,
    required this.isActive,
    required this.joinedAt,
    required this.lastActive,
    this.profileImageUrl,
    this.address,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedUntil,
    this.invitedBy,
    this.lastLoginIp,
    this.loginCount = 0,
    this.totalSpent = 0.0,
    this.fraudRiskScore = 0,
    this.forcePasswordReset = false,
  });

  static String _parseRole(Map<String, dynamic> json) {
    // Handle 'roles' list from search endpoint (e.g. ["admin"])
    if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      return (json['roles'] as List).first.toString();
    }
    // Handle 'role' as object with 'name' from detail endpoint
    if (json['role'] is Map) {
      return json['role']['name'] ?? 'customer';
    }
    // Handle 'role' as string
    if (json['role'] is String) {
      return json['role'];
    }
    // Fallback to role_id
    return json['role_id']?.toString() ?? 'customer';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['full_name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: _parseRole(json),
      kycStatus: json['kyc_status'] ?? 'not_submitted',
      isActive: json['is_active'] ?? true,
      joinedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastActive: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : (json['last_active'] != null ? DateTime.parse(json['last_active']) : DateTime.now()),
      profileImageUrl: json['profile_picture'] ?? json['profile_image_url'],
      address: json['address'],
      suspensionReason: json['suspension_reason'],
      suspendedAt: json['suspended_at'] != null ? DateTime.parse(json['suspended_at']) : null,
      suspendedUntil: json['suspended_until'] != null ? DateTime.parse(json['suspended_until']) : null,
      invitedBy: json['invited_by'],
      lastLoginIp: json['last_login_ip'],
      loginCount: json['login_count'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      fraudRiskScore: json['fraud_risk_score'] ?? 0,
      forcePasswordReset: json['force_password_reset'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'kyc_status': kycStatus,
      'is_active': isActive,
      'created_at': joinedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'profile_image_url': profileImageUrl,
      'address': address,
      'suspension_reason': suspensionReason,
      'suspended_at': suspendedAt?.toIso8601String(),
      'suspended_until': suspendedUntil?.toIso8601String(),
      'invited_by': invitedBy,
      'last_login_ip': lastLoginIp,
      'login_count': loginCount,
      'total_spent': totalSpent,
      'fraud_risk_score': fraudRiskScore,
      'force_password_reset': forcePasswordReset,
    };
  }

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? kycStatus,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? lastActive,
    String? profileImageUrl,
    String? address,
    String? suspensionReason,
    DateTime? suspendedAt,
    DateTime? suspendedUntil,
    String? invitedBy,
    String? lastLoginIp,
    int? loginCount,
    double? totalSpent,
    int? fraudRiskScore,
    bool? forcePasswordReset,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActive: lastActive ?? this.lastActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      invitedBy: invitedBy ?? this.invitedBy,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      loginCount: loginCount ?? this.loginCount,
      totalSpent: totalSpent ?? this.totalSpent,
      fraudRiskScore: fraudRiskScore ?? this.fraudRiskScore,
      forcePasswordReset: forcePasswordReset ?? this.forcePasswordReset,
    );
  }
}
