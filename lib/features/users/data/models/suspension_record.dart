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
