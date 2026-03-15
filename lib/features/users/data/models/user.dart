class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String userType;
  final String status;
  final String kycStatus;
  final bool isActive;
  final bool isSuperuser;
  final String? profilePicture;
  final String? role;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.status,
    required this.kycStatus,
    required this.isActive,
    this.isSuperuser = false,
    this.profilePicture,
    this.role,
    this.suspensionReason,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['full_name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      userType: json['user_type'] ?? 'customer',
      status: json['status'] ?? 'active',
      kycStatus: json['kyc_status'] ?? 'not_submitted',
      isActive: json['is_active'] ?? true,
      isSuperuser: json['is_superuser'] ?? false,
      profilePicture: json['profile_picture'],
      role: json['role'],
      suspensionReason: json['suspension_reason'] ?? json['deletion_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
    );
  }
}
