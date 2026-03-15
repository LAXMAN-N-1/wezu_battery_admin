class KYCDocument {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String documentType;
  final String? documentNumber;
  final String fileUrl;
  final String status;
  final String? rejectionReason;
  final DateTime? uploadedAt;
  final DateTime? verifiedAt;
  final int? verifiedBy;

  const KYCDocument({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.documentType,
    this.documentNumber,
    required this.fileUrl,
    required this.status,
    this.rejectionReason,
    this.uploadedAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory KYCDocument.fromJson(Map<String, dynamic> json) {
    return KYCDocument(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] ?? 'Unknown',
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      documentType: json['document_type'] ?? '',
      documentNumber: json['document_number'],
      fileUrl: json['file_url'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      verifiedBy: json['verified_by'],
    );
  }

  String get documentTypeDisplay {
    switch (documentType) {
      case 'aadhaar':
        return 'Aadhaar Card';
      case 'pan':
        return 'PAN Card';
      case 'driving_license':
        return 'Driving License';
      case 'passport':
        return 'Passport';
      default:
        return documentType.toUpperCase();
    }
  }
}

class KYCStats {
  final int totalDocuments;
  final int totalPending;
  final int totalVerified;
  final int totalRejected;
  final int pendingUsers;

  const KYCStats({
    required this.totalDocuments,
    required this.totalPending,
    required this.totalVerified,
    required this.totalRejected,
    required this.pendingUsers,
  });

  factory KYCStats.fromJson(Map<String, dynamic> json) {
    return KYCStats(
      totalDocuments: json['total_documents'] ?? 0,
      totalPending: json['total_pending'] ?? 0,
      totalVerified: json['total_verified'] ?? 0,
      totalRejected: json['total_rejected'] ?? 0,
      pendingUsers: json['pending_users'] ?? 0,
    );
  }
}
