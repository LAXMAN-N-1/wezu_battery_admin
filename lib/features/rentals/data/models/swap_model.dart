class SwapSession {
  final int id;
  final String userName;
  final int stationId;
  final double oldBatterySoc;
  final double newBatterySoc;
  final String status;
  final DateTime createdAt;

  const SwapSession({
    required this.id,
    required this.userName,
    required this.stationId,
    required this.oldBatterySoc,
    required this.newBatterySoc,
    required this.status,
    required this.createdAt,
  });

  factory SwapSession.fromJson(Map<String, dynamic> json) {
    return SwapSession(
      id: json['id'] as int,
      userName: json['user_name'] ?? 'Unknown',
      stationId: json['station_id'] as int,
      oldBatterySoc: (json['old_battery_soc'] as num?)?.toDouble() ?? 0.0,
      newBatterySoc: (json['new_battery_soc'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'completed',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
