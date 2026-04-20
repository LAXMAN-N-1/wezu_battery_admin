class SuspensionRecord {
  final int id;
  final int userId;
  final String userName;
  final String reason; // 'fraud', 'non_compliance', 'user_request', 'policy_violation', 'other'
  final String? notes;
  final String suspendedBy;
  final DateTime suspendedAt;
  final DateTime? reactivateAt;
  final DateTime? reactivatedAt;
  final String? reactivatedBy;
  final bool isActive;

  const SuspensionRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reason,
    this.notes,
    required this.suspendedBy,
    required this.suspendedAt,
    this.reactivateAt,
    this.reactivatedAt,
    this.reactivatedBy,
    this.isActive = true,
  });

  factory SuspensionRecord.fromJson(Map<String, dynamic> json) {
    return SuspensionRecord(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      reason: json['reason'] ?? 'other',
      notes: json['notes'],
      suspendedBy: json['suspended_by'] ?? 'Admin',
      suspendedAt: json['suspended_at'] != null
          ? DateTime.parse(json['suspended_at'])
          : DateTime.now(),
      reactivateAt: json['reactivate_at'] != null
          ? DateTime.parse(json['reactivate_at'])
          : null,
      reactivatedAt: json['reactivated_at'] != null
          ? DateTime.parse(json['reactivated_at'])
          : null,
      reactivatedBy: json['reactivated_by'],
      isActive: json['is_active'] ?? true,
    );
  }

  String get reasonLabel {
    switch (reason) {
      case 'fraud': return 'Fraud';
      case 'non_compliance': return 'Non-Compliance';
      case 'user_request': return 'User Request';
      case 'policy_violation': return 'Policy Violation';
      case 'other': return 'Other';
      default: return reason;
    }
  }

  String get status {
    if (reactivatedAt != null) return 'Reactivated';
    if (reactivateAt != null && DateTime.now().isAfter(reactivateAt!)) return 'Expired';
    return 'Active';
  }
}
