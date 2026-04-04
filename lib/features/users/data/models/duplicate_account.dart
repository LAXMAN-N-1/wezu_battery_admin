class DuplicateAccount {
  final int id;
  final int primaryUserId;
  final int suspectedDuplicateUserId;
  final int? matchingDeviceId;
  final bool matchingPhone;
  final bool matchingEmail;
  final bool matchingIp;
  final bool matchingAddress;
  final bool matchingPaymentMethod;
  final double deviceSimilarityScore;
  final double behaviorSimilarityScore;
  final double overallConfidence;
  final String status;
  final int? investigatedBy;
  final DateTime? investigatedAt;
  final String? actionTaken;
  final String? notes;
  final DateTime detectedAt;

  DuplicateAccount({
    required this.id,
    required this.primaryUserId,
    required this.suspectedDuplicateUserId,
    this.matchingDeviceId,
    required this.matchingPhone,
    required this.matchingEmail,
    required this.matchingIp,
    required this.matchingAddress,
    required this.matchingPaymentMethod,
    required this.deviceSimilarityScore,
    required this.behaviorSimilarityScore,
    required this.overallConfidence,
    required this.status,
    this.investigatedBy,
    this.investigatedAt,
    this.actionTaken,
    this.notes,
    required this.detectedAt,
  });

  factory DuplicateAccount.fromJson(Map<String, dynamic> json) {
    return DuplicateAccount(
      id: json['id'] as int,
      primaryUserId: json['primary_user_id'] as int,
      suspectedDuplicateUserId: json['suspected_duplicate_user_id'] as int,
      matchingDeviceId: json['matching_device_id'] as int?,
      matchingPhone: json['matching_phone'] ?? false,
      matchingEmail: json['matching_email'] ?? false,
      matchingIp: json['matching_ip'] ?? false,
      matchingAddress: json['matching_address'] ?? false,
      matchingPaymentMethod: json['matching_payment_method'] ?? false,
      deviceSimilarityScore: (json['device_similarity_score'] ?? 0.0).toDouble(),
      behaviorSimilarityScore: (json['behavior_similarity_score'] ?? 0.0).toDouble(),
      overallConfidence: (json['overall_confidence'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'DETECTED',
      investigatedBy: json['investigated_by'] as int?,
      investigatedAt: json['investigated_at'] != null ? DateTime.parse(json['investigated_at']) : null,
      actionTaken: json['action_taken'],
      notes: json['notes'],
      detectedAt: json['detected_at'] != null ? DateTime.parse(json['detected_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primary_user_id': primaryUserId,
      'suspected_duplicate_user_id': suspectedDuplicateUserId,
      'matching_device_id': matchingDeviceId,
      'matching_phone': matchingPhone,
      'matching_email': matchingEmail,
      'matching_ip': matchingIp,
      'matching_address': matchingAddress,
      'matching_payment_method': matchingPaymentMethod,
      'device_similarity_score': deviceSimilarityScore,
      'behavior_similarity_score': behaviorSimilarityScore,
      'overall_confidence': overallConfidence,
      'status': status,
      'investigated_by': investigatedBy,
      'investigated_at': investigatedAt?.toIso8601String(),
      'action_taken': actionTaken,
      'notes': notes,
      'detected_at': detectedAt.toIso8601String(),
    };
  }
}
