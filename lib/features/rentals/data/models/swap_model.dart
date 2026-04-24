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

class SwapSession {
  final int id;
  final String userName;
  final int stationId;
  final int rentalId;
  final int oldBatteryId;
  final int newBatteryId;
  final double oldBatterySoc;
  final double newBatterySoc;
  final String status;
  final DateTime createdAt;

  const SwapSession({
    required this.id,
    required this.userName,
    required this.stationId,
    this.rentalId = 0,
    this.oldBatteryId = 0,
    this.newBatteryId = 0,
    required this.oldBatterySoc,
    required this.newBatterySoc,
    required this.status,
    required this.createdAt,
  });

  factory SwapSession.fromJson(Map<String, dynamic> json) {
    return SwapSession(
      id: _asInt(json['id']),
      userName: (json['user_name'] ?? json['user']?['name'] ?? 'Unknown')
          .toString(),
      stationId: _asInt(json['station_id']),
      rentalId: _asInt(json['rental_id']),
      oldBatteryId: _asInt(
        json['old_battery_id'] ?? json['from_battery_id'] ?? json['old_battery'],
      ),
      newBatteryId: _asInt(
        json['new_battery_id'] ?? json['to_battery_id'] ?? json['new_battery'],
      ),
      oldBatterySoc: _asDouble(json['old_battery_soc'] ?? json['old_soc']),
      newBatterySoc: _asDouble(json['new_battery_soc'] ?? json['new_soc']),
      status: (json['status'] ?? 'completed').toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
