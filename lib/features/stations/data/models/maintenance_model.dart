class MaintenanceRecord {
  final int id;
  final String entityType;
  final int entityId;
  final int technicianId;
  final String maintenanceType;
  final String description;
  final double cost;
  final String? partsReplaced;
  final String status;
  final DateTime performedAt;

  MaintenanceRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.technicianId,
    required this.maintenanceType,
    required this.description,
    required this.cost,
    this.partsReplaced,
    required this.status,
    required this.performedAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] ?? 0,
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? 0,
      technicianId: json['technician_id'] ?? 0,
      maintenanceType: json['maintenance_type'] ?? '',
      description: json['description'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      partsReplaced: json['parts_replaced'],
      status: json['status'] ?? 'completed',
      performedAt: DateTime.tryParse(json['performed_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class MaintenanceStats {
  final int total;
  final int completed;
  final int scheduled;
  final int inProgress;
  final double totalCost;
  final int stationsInMaintenance;

  const MaintenanceStats({
    required this.total,
    int? totalRecords,
    required this.completed,
    required this.scheduled,
    required this.inProgress,
    required this.totalCost,
    this.stationsInMaintenance = 0,
  });

  factory MaintenanceStats.fromJson(Map<String, dynamic> json) {
    return MaintenanceStats(
      total: json['total'] ?? json['total_records'] ?? 0,
      completed: json['completed'] ?? 0,
      scheduled: json['scheduled'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      stationsInMaintenance: json['stations_in_maintenance'] ?? 0,
    );
  }
}
