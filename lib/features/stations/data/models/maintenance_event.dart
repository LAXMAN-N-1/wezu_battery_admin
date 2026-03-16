import 'package:flutter/material.dart';

enum MaintenanceStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case MaintenanceStatus.scheduled: return 'Scheduled';
      case MaintenanceStatus.inProgress: return 'In Progress';
      case MaintenanceStatus.completed: return 'Completed';
      case MaintenanceStatus.cancelled: return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case MaintenanceStatus.scheduled: return Colors.blue;
      case MaintenanceStatus.inProgress: return Colors.orange;
      case MaintenanceStatus.completed: return Colors.green;
      case MaintenanceStatus.cancelled: return Colors.red;
    }
  }
}

enum MaintenanceType {
  routine,
  repair,
  inspection,
  emergency;

  String get label {
    switch (this) {
      case MaintenanceType.routine: return 'Routine';
      case MaintenanceType.repair: return 'Repair';
      case MaintenanceType.inspection: return 'Inspection';
      case MaintenanceType.emergency: return 'Emergency';
    }
  }
}

class MaintenanceEvent {
  final String id;
  final int stationId;
  final String stationName;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final MaintenanceStatus status;
  final MaintenanceType type;
  final String? assignedCrew;
  final String? recurrenceRule; // rrule string

  const MaintenanceEvent({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.type,
    this.assignedCrew,
    this.recurrenceRule,
  });

  factory MaintenanceEvent.fromJson(Map<String, dynamic> json) {
    return MaintenanceEvent(
      id: json['id']?.toString() ?? '',
      stationId: json['station_id'] as int? ?? 0,
      stationName: json['station_name'] as String? ?? 'Unknown Station',
      title: json['title'] as String? ?? 'Maintenance',
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MaintenanceStatus.scheduled,
      ),
      type: MaintenanceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MaintenanceType.routine,
      ),
      assignedCrew: json['assigned_crew'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'assigned_crew': assignedCrew,
      'recurrence_rule': recurrenceRule,
    };
  }

  MaintenanceEvent copyWith({
    String? id,
    int? stationId,
    String? stationName,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    MaintenanceStatus? status,
    MaintenanceType? type,
    String? assignedCrew,
    String? recurrenceRule,
  }) {
    return MaintenanceEvent(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      type: type ?? this.type,
      assignedCrew: assignedCrew ?? this.assignedCrew,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
}
