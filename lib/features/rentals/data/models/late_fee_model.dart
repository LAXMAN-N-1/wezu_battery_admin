class LateFee {
  final int id;
  final String userName;
  final int daysOverdue;
  final double totalLateFee;
  final String paymentStatus;
  final String waiverStatus;
  final int? waiverId;
  final DateTime createdAt;

  const LateFee({
    required this.id,
    required this.userName,
    required this.daysOverdue,
    required this.totalLateFee,
    required this.paymentStatus,
    required this.waiverStatus,
    this.waiverId,
    required this.createdAt,
  });

  factory LateFee.fromJson(Map<String, dynamic> json) {
    return LateFee(
      id: json['id'] as int,
      userName: json['user_name'] ?? 'Unknown',
      daysOverdue: json['days_overdue'] ?? 0,
      totalLateFee: (json['total_late_fee'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'PENDING',
      waiverStatus: json['waiver_status'] ?? 'NONE',
      waiverId: json['waiver_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
