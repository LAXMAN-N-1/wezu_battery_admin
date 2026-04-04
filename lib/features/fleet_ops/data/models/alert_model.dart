class FleetAlert {
  final int id;
  final int? stationId;
  final String alertType;
  final String severity;
  final String message;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;

  FleetAlert({
    required this.id,
    this.stationId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.createdAt,
    this.acknowledgedAt,
  });

  factory FleetAlert.fromJson(Map<String, dynamic> json) {
    return FleetAlert(
      id: json['id'],
      stationId: json['station_id'],
      alertType: json['alert_type'],
      severity: json['severity'] ?? 'MEDIUM',
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at']) : null,
    );
  }
}
