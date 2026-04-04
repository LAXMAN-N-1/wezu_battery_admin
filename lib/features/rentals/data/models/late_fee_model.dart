class LateFee {
  final int id;
  final int rentalId;
  final String userName;
  final int daysOverdue;
  final double dailyRate;
  final double baseFee;
  final double totalLateFee;
  final String paymentStatus;
  final String waiverStatus;
  final int? waiverId;
  final DateTime createdAt;

  const LateFee({
    required this.id,
    this.rentalId = 0,
    required this.userName,
    required this.daysOverdue,
    this.dailyRate = 0.0,
    this.baseFee = 0.0,
    required this.totalLateFee,
    required this.paymentStatus,
    required this.waiverStatus,
    this.waiverId,
    required this.createdAt,
  });

  factory LateFee.fromJson(Map<String, dynamic> json) {
    return LateFee(
      id: json['id'] as int,
      rentalId: json['rental_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      daysOverdue: json['days_overdue'] ?? 0,
      dailyRate: (json['daily_late_fee_rate'] as num?)?.toDouble() ?? 0.0,
      baseFee: (json['base_late_fee'] as num?)?.toDouble() ?? 0.0,
      totalLateFee: (json['total_late_fee'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'PENDING',
      waiverStatus: json['waiver_status'] ?? 'NONE',
      waiverId: json['waiver_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
