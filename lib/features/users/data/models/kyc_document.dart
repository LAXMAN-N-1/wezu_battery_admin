class KycDocument {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String documentType; 
  final String? documentNumber;
  final String fileUrl;
  final String status; 
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final double? qualityScore;

  const KycDocument({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.documentType,
    this.documentNumber,
    required this.fileUrl,
    required this.status,
    this.reviewedBy,
    this.reviewNotes,
    required this.uploadedAt,
    this.reviewedAt,
    this.qualityScore,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json, {String? defaultUserName, String? defaultUserEmail}) {
    return KycDocument(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: defaultUserName ?? 'Unknown User',
      userEmail: defaultUserEmail ?? '',
      documentType: json['document_type'] ?? 'unknown',
      documentNumber: json['document_number'],
      fileUrl: json['file_url'] ?? '',
      status: json['status'] ?? 'pending',
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at']) : DateTime.now(),
    );
  }

  KycDocument copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userEmail,
    String? documentType,
    String? documentNumber,
    String? fileUrl,
    String? status,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    double? qualityScore,
  }) {
    return KycDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }

  String get typeLabel {
    switch (documentType) {
      case 'national_id': return 'National ID';
      case 'passport': return 'Passport';
      case 'driving_license': return 'Driving License';
      case 'address_proof': return 'Address Proof';
      default: return documentType.toUpperCase();
    }
  }
}
