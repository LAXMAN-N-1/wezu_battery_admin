class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // 'admin', 'customer', 'driver', 'dealer'
  final String kycStatus; // 'verified', 'pending', 'rejected', 'not_submitted'
  final bool isActive;
  final DateTime joinedAt;
  final DateTime lastActive;

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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['full_name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: (json['roles'] as List?)?.isNotEmpty == true 
          ? json['roles'][0] 
          : json['role'] ?? 'customer',
      kycStatus: json['kyc_status'] ?? 'not_submitted',
      isActive: json['is_active'] ?? true,
      joinedAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      lastActive: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : (json['last_active'] != null ? DateTime.parse(json['last_active']) : DateTime.now()),
    );
  }
}
