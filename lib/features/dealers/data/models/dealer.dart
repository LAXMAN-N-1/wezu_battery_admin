class DealerProfile {
  final int id;
  final int userId;
  final String businessName;
  final String? gstNumber;
  final String? panNumber;
  final String contactPerson;
  final String contactEmail;
  final String contactPhone;
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;
  final bool isActive;
  final DateTime createdAt;

  const DealerProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.gstNumber,
    this.panNumber,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isActive,
    required this.createdAt,
  });

  factory DealerProfile.fromJson(Map<String, dynamic> json) {
    return DealerProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      businessName: json['business_name'] ?? '',
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],
      contactPerson: json['contact_person'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class DealerStats {
  final int totalActiveDealers;
  final int pendingOnboardings;
  final double totalCommissionsPaid;

  const DealerStats({
    required this.totalActiveDealers,
    required this.pendingOnboardings,
    required this.totalCommissionsPaid,
  });

  factory DealerStats.fromJson(Map<String, dynamic> json) {
    return DealerStats(
      totalActiveDealers: json['total_active_dealers'] ?? 0,
      pendingOnboardings: json['pending_onboardings'] ?? 0,
      totalCommissionsPaid: (json['total_commissions_paid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
