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

DateTime _asDate(dynamic value, [DateTime? fallback]) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed ?? fallback ?? DateTime.now();
}

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
  final int? pickupStationId;
  final String? battery;
  final int? startStationId;
  final double securityDeposit;

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
    this.pickupStationId,
    this.battery,
    this.startStationId,
    this.securityDeposit = 0.0,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    final start = _asDate(
      json['start_time'] ?? json['started_at'] ?? json['created_at'],
    );

    return Rental(
      id: _asInt(json['id']),
      userName: (json['user_name'] ??
              json['customer_name'] ??
              json['user']?['name'] ??
              'Unknown')
          .toString(),
      batteryId: _asInt(
        json['battery_id'] ?? json['battery']?['id'] ?? json['battery'],
      ),
      startTime: start,
      endTime: json['end_time'] != null || json['ended_at'] != null
          ? _asDate(json['end_time'] ?? json['ended_at'])
          : null,
      expectedEndTime: _asDate(
        json['expected_end_time'] ?? json['due_time'] ?? json['end_time'],
        start,
      ),
      totalAmount: _asDouble(json['total_amount'] ?? json['amount']),
      status: (json['status'] ?? 'active').toString(),
      batteryLevel:
          json['battery_level'] == null && json['current_soc'] == null
          ? null
          : _asDouble(json['battery_level'] ?? json['current_soc']),
      pickupStationId: json['pickup_station_id'] == null
          ? null
          : _asInt(json['pickup_station_id']),
      battery: json['battery']?.toString(),
      startStationId:
          json['start_station_id'] == null && json['pickup_station_id'] == null
          ? null
          : _asInt(json['start_station_id'] ?? json['pickup_station_id']),
      securityDeposit: _asDouble(json['security_deposit']),
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
      activeRentals: _asInt(
        json['active_rentals'] ?? json['active'] ?? json['ongoing'],
      ),
      overdueRentals: _asInt(
        json['overdue_rentals'] ?? json['overdue'] ?? json['late'],
      ),
      totalSwapsCompleted: _asInt(
        json['total_swaps_completed'] ?? json['swaps_completed'],
      ),
      todayRevenue: _asDouble(json['today_revenue'] ?? json['revenue_today']),
    );
  }
}
