enum KycStatus {
  pending,
  approved,
  rejected,
  none;

  String get label {
    switch (this) {
      case KycStatus.pending: return 'Pending';
      case KycStatus.approved: return 'Approved';
      case KycStatus.rejected: return 'Rejected';
      case KycStatus.none: return 'None';
    }
  }
}

enum AccountStatus {
  active,
  suspended,
  banned;

  String get label {
    switch (this) {
      case AccountStatus.active: return 'Active';
      case AccountStatus.suspended: return 'Suspended';
      case AccountStatus.banned: return 'Banned';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime registrationDate;
  final KycStatus kycStatus;
  final AccountStatus accountStatus;
  final DateTime lastActive;
  final double walletBalance;
  final int totalSwaps;
  final String? profilePhotoUrl;
  final List<String> vehicles;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.registrationDate,
    required this.kycStatus,
    required this.accountStatus,
    required this.lastActive,
    required this.walletBalance,
    required this.totalSwaps,
    this.profilePhotoUrl,
    this.vehicles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      registrationDate: DateTime.parse(json['registration_date']),
      kycStatus: KycStatus.values.firstWhere(
        (e) => e.name == json['kyc_status'],
        orElse: () => KycStatus.none,
      ),
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == json['account_status'],
        orElse: () => AccountStatus.active,
      ),
      lastActive: DateTime.parse(json['last_active']),
      walletBalance: (json['wallet_balance'] as num).toDouble(),
      totalSwaps: json['total_swaps'],
      profilePhotoUrl: json['profile_photo_url'],
      vehicles: List<String>.from(json['vehicles'] ?? []),
    );
  }
}
