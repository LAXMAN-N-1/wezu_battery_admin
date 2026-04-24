int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

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
      id: _asInt(json['id']),
      rentalId: _asInt(json['rental_id']),
      userName: (json['user_name'] ?? json['customer_name'] ?? 'Unknown')
          .toString(),
      daysOverdue: _asInt(json['days_overdue']),
      dailyRate: _asDouble(
        json['daily_late_fee_rate'] ?? json['daily_rate'] ?? json['rate'],
      ),
      baseFee: _asDouble(json['base_late_fee'] ?? json['base_fee']),
      totalLateFee: _asDouble(
        json['total_late_fee'] ?? json['total_fee'] ?? json['amount'],
      ),
      paymentStatus: (json['payment_status'] ?? 'PENDING').toString(),
      waiverStatus: (json['waiver_status'] ?? 'NONE').toString(),
      waiverId: json['waiver_id'] == null ? null : _asInt(json['waiver_id']),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
