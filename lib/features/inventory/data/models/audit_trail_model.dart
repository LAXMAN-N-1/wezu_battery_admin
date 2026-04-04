class AuditTrailEntry {
  final int id;
  final int batteryId;
  final String actionType;
  final String? fromLocationType;
  final int? fromLocationId;
  final String? toLocationType;
  final int? toLocationId;
  final int? actorId;
  final String actorName;
  final String? notes;
  final DateTime timestamp;

  AuditTrailEntry({
    required this.id,
    required this.batteryId,
    required this.actionType,
    this.fromLocationType,
    this.fromLocationId,
    this.toLocationType,
    this.toLocationId,
    this.actorId,
    required this.actorName,
    this.notes,
    required this.timestamp,
  });

  factory AuditTrailEntry.fromJson(Map<String, dynamic> json) {
    return AuditTrailEntry(
      id: json['id'] ?? 0,
      batteryId: json['battery_id'] ?? 0,
      actionType: json['action_type'] ?? '',
      fromLocationType: json['from_location_type'],
      fromLocationId: json['from_location_id'],
      toLocationType: json['to_location_type'],
      toLocationId: json['to_location_id'],
      actorId: json['actor_id'],
      actorName: json['actor_name'] ?? 'System',
      notes: json['notes'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class AuditTrailStats {
  final int totalEntries;
  final int todayCount;
  final int weekCount;
  final int transfers;
  final int disposals;
  final int statusChanges;
  final int manualEntries;

  AuditTrailStats({
    required this.totalEntries,
    required this.todayCount,
    required this.weekCount,
    required this.transfers,
    required this.disposals,
    required this.statusChanges,
    required this.manualEntries,
  });

  factory AuditTrailStats.fromJson(Map<String, dynamic> json) {
    return AuditTrailStats(
      totalEntries: json['total_entries'] ?? 0,
      todayCount: json['today_count'] ?? 0,
      weekCount: json['week_count'] ?? 0,
      transfers: json['transfers'] ?? 0,
      disposals: json['disposals'] ?? 0,
      statusChanges: json['status_changes'] ?? 0,
      manualEntries: json['manual_entries'] ?? 0,
    );
  }
}
