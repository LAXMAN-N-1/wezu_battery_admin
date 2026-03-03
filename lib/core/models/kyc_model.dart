import 'user_model.dart';

enum DocumentType {
  nationalId,
  driversLicense,
  passport;

  String get label {
    switch (this) {
      case DocumentType.nationalId: return 'National ID';
      case DocumentType.driversLicense: return "Driver's License";
      case DocumentType.passport: return 'Passport';
    }
  }
}

class KycRequest {
  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final DocumentType documentType;
  final List<String> documentUrls;
  final KycStatus status;
  final DateTime submittedAt;
  final String? rejectionReason;
  final String? verifierName;
  final DateTime? verifiedAt;

  KycRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.documentType,
    required this.documentUrls,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
    this.verifierName,
    this.verifiedAt,
  });

  factory KycRequest.fromJson(Map<String, dynamic> json) {
    return KycRequest(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userPhone: json['user_phone'],
      documentType: DocumentType.values.firstWhere(
        (e) => e.name == json['document_type'],
        orElse: () => DocumentType.nationalId,
      ),
      documentUrls: List<String>.from(json['document_urls'] ?? []),
      status: KycStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => KycStatus.pending,
      ),
      submittedAt: DateTime.parse(json['submitted_at']),
      rejectionReason: json['rejection_reason'],
      verifierName: json['verifier_name'],
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
    );
  }
}
