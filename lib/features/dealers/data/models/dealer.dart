class DealerProfile {
  final int id;
  final int userId;
  final String businessName;
  final String? gstNumber;
  final String? panNumber;
  final String contactPerson;
  final String? contactEmail;
  final String contactPhone;
  final String? addressLine1;
  final String city;
  final String? state;
  final String? pincode;
  final bool isActive;
  final DateTime createdAt;

  const DealerProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.gstNumber,
    this.panNumber,
    required this.contactPerson,
    this.contactEmail,
    required this.contactPhone,
    this.addressLine1,
    required this.city,
    this.state,
    this.pincode,
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
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'] ?? '',
      addressLine1: json['address_line1'],
      city: json['city'] ?? '',
      state: json['state'],
      pincode: json['pincode'],
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
    final active = json['total_active_dealers'] ?? json['totalActiveDealers'];
    final pending = json['pending_onboardings'] ?? json['pendingOnboardings'];
    final commissions = json['total_commissions_paid'] ?? json['totalCommissionsPaid'];
    return DealerStats(
      totalActiveDealers: (active as num?)?.toInt() ?? 0,
      pendingOnboardings: (pending as num?)?.toInt() ?? 0,
      totalCommissionsPaid: (commissions as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DealerKycDocument {
  final int id;
  final int dealerId;
  final String businessName;
  final String documentType;
  final String fileUrl;
  final bool isVerified;
  final DateTime? uploadedAt;

  const DealerKycDocument({
    required this.id,
    required this.dealerId,
    required this.businessName,
    required this.documentType,
    required this.fileUrl,
    required this.isVerified,
    this.uploadedAt,
  });

  factory DealerKycDocument.fromJson(Map<String, dynamic> json) {
    return DealerKycDocument(
      id: json['id'] as int,
      dealerId: json['dealer_id'] as int,
      businessName: json['business_name'] ?? 'Unknown Dealer',
      documentType: json['document_type'] ?? '',
      fileUrl: json['file_url'] ?? '',
      isVerified: json['is_verified'] ?? false,
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at']) : null,
    );
  }
}
