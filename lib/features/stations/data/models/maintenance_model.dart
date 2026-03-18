class MaintenanceRecord {
  final int id;
  final String entityType;
  final int entityId;
  final String? entityName;
  final int technicianId;
  final String maintenanceType;
  final String description;
  final double cost;
  final String? partsReplaced;
  final String status;
  final DateTime? performedAt;

  const MaintenanceRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.entityName,
    required this.technicianId,
    required this.maintenanceType,
    required this.description,
    this.cost = 0.0,
    this.partsReplaced,
    required this.status,
    this.performedAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as int,
      entityType: json['entity_type'] ?? 'station',
      entityId: json['entity_id'] ?? 0,
      entityName: json['entity_name'],
      technicianId: json['technician_id'] ?? 0,
      maintenanceType: json['maintenance_type'] ?? 'preventive',
      description: json['description'] ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      partsReplaced: json['parts_replaced'],
      status: json['status'] ?? 'completed',
      performedAt: json['performed_at'] != null ? DateTime.parse(json['performed_at']) : null,
    );
  }

  String get maintenanceTypeDisplay {
    switch (maintenanceType) {
      case 'preventive': return 'Preventive';
      case 'corrective': return 'Corrective';
      case 'emergency': return 'Emergency';
      default: return maintenanceType;
    }
  }
}

class MaintenanceStats {
  final int totalRecords;
  final int completed;
  final int scheduled;
  final int inProgress;
  final double totalCost;
  final int stationsInMaintenance;

  const MaintenanceStats({
    required this.totalRecords,
    required this.completed,
    required this.scheduled,
    required this.inProgress,
    required this.totalCost,
    required this.stationsInMaintenance,
  });

  factory MaintenanceStats.fromJson(Map<String, dynamic> json) {
    return MaintenanceStats(
      totalRecords: json['total_records'] ?? 0,
      completed: json['completed'] ?? 0,
      scheduled: json['scheduled'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      stationsInMaintenance: json['stations_in_maintenance'] ?? 0,
    );
  }
}
