class Battery {
  final String id; // UUID
  final String serialNumber;
  final String? batteryType;
  final String status;
  final double healthPercentage;
  final String locationType;
  final String? locationName;
  final int cycleCount;
  final int totalCycles;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? manufacturer;
  final DateTime? manufactureDate;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final DateTime? lastChargedAt;
  final DateTime? lastInspectedAt;
  final String? notes;

  Battery({
    required this.id,
    required this.serialNumber,
    this.batteryType,
    required this.status,
    required this.healthPercentage,
    required this.locationType,
    this.locationName,
    required this.cycleCount,
    required this.totalCycles,
    required this.updatedAt,
    required this.createdAt,
    this.manufacturer,
    this.manufactureDate,
    this.purchaseDate,
    this.warrantyExpiry,
    this.lastChargedAt,
    this.lastInspectedAt,
    this.notes,
  });

  factory Battery.fromJson(Map<String, dynamic> json) {
    return Battery(
      id: json['id'] as String,
      serialNumber: json['serial_number'] as String,
      batteryType: json['battery_type'],
      status: json['status'] ?? 'unknown',
      healthPercentage: (json['health_percentage'] as num?)?.toDouble() ?? 100.0,
      locationType: json['location_type'] ?? 'warehouse',
      locationName: json['location_name'] ?? json['station']?['name'] ?? 'Warehouse',
      cycleCount: json['cycle_count'] ?? 0,
      totalCycles: json['total_cycles'] ?? 0,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      manufacturer: json['manufacturer'],
      manufactureDate: json['manufacture_date'] != null
          ? DateTime.parse(json['manufacture_date'])
          : null,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      warrantyExpiry: json['warranty_expiry'] != null
          ? DateTime.parse(json['warranty_expiry'])
          : null,
      lastChargedAt: json['last_charged_at'] != null
          ? DateTime.parse(json['last_charged_at'])
          : null,
      lastInspectedAt: json['last_inspected_at'] != null
          ? DateTime.parse(json['last_inspected_at'])
          : null,
      notes: json['notes'],
    );
  }
}

class BatteryAuditLog {
  final int id;
  final String batteryId; // UUID
  final String fieldChanged;
  final String? oldValue;
  final String? newValue;
  final String? reason;
  final DateTime timestamp;
  final String? changedBy;

  BatteryAuditLog({
    required this.id,
    required this.batteryId,
    required this.fieldChanged,
    this.oldValue,
    this.newValue,
    this.reason,
    required this.timestamp,
    this.changedBy,
  });

  factory BatteryAuditLog.fromJson(Map<String, dynamic> json) {
    return BatteryAuditLog(
      id: json['id'],
      batteryId: json['battery_id'] as String,
      fieldChanged: json['field_changed'],
      oldValue: json['old_value'],
      newValue: json['new_value'],
      reason: json['reason'],
      timestamp: DateTime.parse(json['timestamp']),
      changedBy: json['changed_by']?.toString(),
    );
  }
}

class BatteryHealthHistory {
  final int id;
  final String batteryId; // UUID
  final double healthPercentage;
  final DateTime recordedAt;

  BatteryHealthHistory({
    required this.id,
    required this.batteryId,
    required this.healthPercentage,
    required this.recordedAt,
  });

  factory BatteryHealthHistory.fromJson(Map<String, dynamic> json) {
    return BatteryHealthHistory(
      id: json['id'],
      batteryId: json['battery_id'] as String,
      healthPercentage: (json['health_percentage'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}
