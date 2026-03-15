class Rental {
  final int id;
  final String userName;
  final int batteryId;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime expectedEndTime;
  final double totalAmount;
  final String status;
  final double? batteryLevel;

  const Rental({
    required this.id,
    required this.userName,
    required this.batteryId,
    required this.startTime,
    this.endTime,
    required this.expectedEndTime,
    required this.totalAmount,
    required this.status,
    this.batteryLevel,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] as int,
      userName: json['user_name'] ?? 'Unknown',
      batteryId: json['battery_id'] as int,
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      expectedEndTime: DateTime.parse(json['expected_end_time'] ?? json['start_time']),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'active',
      batteryLevel: (json['battery_level'] as num?)?.toDouble(),
    );
  }
}

class RentalStats {
  final int activeRentals;
  final int overdueRentals;
  final int totalSwapsCompleted;
  final double todayRevenue;

  const RentalStats({
    required this.activeRentals,
    required this.overdueRentals,
    required this.totalSwapsCompleted,
    required this.todayRevenue,
  });

  factory RentalStats.fromJson(Map<String, dynamic> json) {
    return RentalStats(
      activeRentals: json['active_rentals'] ?? 0,
      overdueRentals: json['overdue_rentals'] ?? 0,
      totalSwapsCompleted: json['total_swaps_completed'] ?? 0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
