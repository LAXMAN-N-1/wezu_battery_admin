import 'dart:convert';

// -------------------------------------------------------
// Enum: operational status
// -------------------------------------------------------
enum StationOperationalStatus { operational, error, maintenance, offline }

extension StationOperationalStatusX on StationOperationalStatus {
  String get label {
    switch (this) {
      case StationOperationalStatus.operational:
        return 'Operational';
      case StationOperationalStatus.error:
        return 'Error';
      case StationOperationalStatus.maintenance:
        return 'Maintenance';
      case StationOperationalStatus.offline:
        return 'Offline';
    }
  }

  // Hex colors
  int get colorValue {
    switch (this) {
      case StationOperationalStatus.operational:
        return 0xFF22C55E; // green
      case StationOperationalStatus.error:
        return 0xFFEF4444; // red
      case StationOperationalStatus.maintenance:
        return 0xFFF59E0B; // amber
      case StationOperationalStatus.offline:
        return 0xFF6B7280; // gray
    }
  }

  String get emoji {
    switch (this) {
      case StationOperationalStatus.operational:
        return '🟢';
      case StationOperationalStatus.error:
        return '🔴';
      case StationOperationalStatus.maintenance:
        return '🟡';
      case StationOperationalStatus.offline:
        return '⚫';
    }
  }

  static StationOperationalStatus fromString(String s) {
    return StationOperationalStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => StationOperationalStatus.offline,
    );
  }
}

// -------------------------------------------------------
// A single status event / snapshot for one station
// -------------------------------------------------------
class StationStatusEvent {
  final int stationId;
  final String stationName;
  final String stationAddress;
  final StationOperationalStatus status;
  final DateTime timestamp;
  final String? errorMessage;
  final List<String> troubleshootingSteps;

  const StationStatusEvent({
    required this.stationId,
    required this.stationName,
    required this.stationAddress,
    required this.status,
    required this.timestamp,
    this.errorMessage,
    this.troubleshootingSteps = const [],
  });

  Map<String, dynamic> toJson() => {
    'stationId': stationId,
    'stationName': stationName,
    'stationAddress': stationAddress,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'errorMessage': errorMessage,
    'troubleshootingSteps': troubleshootingSteps,
  };

  String toJsonString() => jsonEncode(toJson());

  factory StationStatusEvent.fromJson(Map<String, dynamic> json) =>
      StationStatusEvent(
        stationId: json['stationId'] as int,
        stationName: json['stationName'] as String,
        stationAddress: json['stationAddress'] as String? ?? '',
        status: StationOperationalStatusX.fromString(json['status'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        errorMessage: json['errorMessage'] as String?,
        troubleshootingSteps: List<String>.from(
          json['troubleshootingSteps'] as List? ?? [],
        ),
      );

  static List<StationStatusEvent> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StationStatusEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// -------------------------------------------------------
// Maintenance schedule for a station
// -------------------------------------------------------
class MaintenanceSchedule {
  final int stationId;
  final DateTime startTime;
  final DateTime endTime;
  final String notes;
  final String maintenanceType; // Routine, Repair, Upgrade, etc.

  const MaintenanceSchedule({
    required this.stationId,
    required this.startTime,
    required this.endTime,
    required this.notes,
    this.maintenanceType = 'Routine',
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming => DateTime.now().isBefore(startTime);

  Map<String, dynamic> toJson() => {
    'stationId': stationId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'notes': notes,
    'maintenanceType': maintenanceType,
  };

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      MaintenanceSchedule(
        stationId: json['stationId'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        notes: json['notes'] as String? ?? '',
        maintenanceType:
            json['maintenanceType'] as String? ??
            json['maintenance_type'] as String? ??
            'Routine',
      );
}

// -------------------------------------------------------
// Alert: a status change notification
// -------------------------------------------------------
class StatusAlert {
  final int stationId;
  final String stationName;
  final StationOperationalStatus previousStatus;
  final StationOperationalStatus newStatus;
  final DateTime timestamp;
  bool dismissed;

  StatusAlert({
    required this.stationId,
    required this.stationName,
    required this.previousStatus,
    required this.newStatus,
    required this.timestamp,
    this.dismissed = false,
  });
}
