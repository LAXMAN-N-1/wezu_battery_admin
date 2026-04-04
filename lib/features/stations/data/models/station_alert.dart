
class BackendStationAlert {
  final String alertId;
  final String alertType;
  final String severity;
  final String message;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;

  const BackendStationAlert({
    required this.alertId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.createdAt,
    this.acknowledgedAt,
  });

  factory BackendStationAlert.fromJson(Map<String, dynamic> json) =>
      BackendStationAlert(
        alertId: json['alert_id'] as String,
        alertType: json['alert_type'] as String,
        severity: json['severity'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        acknowledgedAt: json['acknowledged_at'] != null
            ? DateTime.parse(json['acknowledged_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'alert_id': alertId,
        'alert_type': alertType,
        'severity': severity,
        'message': message,
        'created_at': createdAt.toIso8601String(),
        'acknowledged_at': acknowledgedAt?.toIso8601String(),
      };
}
