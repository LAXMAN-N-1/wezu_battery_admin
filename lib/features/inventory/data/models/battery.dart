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
      id: json['id'].toString(),
      serialNumber: (json['serial_number'] ?? '').toString(),
      batteryType: json['battery_type']?.toString(),
      status: (json['status'] ?? 'unknown').toString(),
      healthPercentage: (json['health_percentage'] is num)
          ? (json['health_percentage'] as num).toDouble()
          : double.tryParse(json['health_percentage']?.toString() ?? '') ?? 100.0,
      locationType: (json['location_type'] ?? 'warehouse').toString(),
      locationName: (json['location_name'] ?? json['station']?['name'] ?? 'Warehouse').toString(),
      cycleCount: (json['cycle_count'] is num)
          ? (json['cycle_count'] as num).toInt()
          : int.tryParse(json['cycle_count']?.toString() ?? '') ?? 0,
      totalCycles: (json['total_cycles'] is num)
          ? (json['total_cycles'] as num).toInt()
          : int.tryParse(json['total_cycles']?.toString() ?? '') ?? 0,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      manufacturer: json['manufacturer']?.toString(),
      manufactureDate: json['manufacture_date'] != null
          ? DateTime.tryParse(json['manufacture_date'].toString())
          : null,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : null,
      warrantyExpiry: json['warranty_expiry'] != null
          ? DateTime.tryParse(json['warranty_expiry'].toString())
          : null,
      lastChargedAt: json['last_charged_at'] != null
          ? DateTime.tryParse(json['last_charged_at'].toString())
          : null,
      lastInspectedAt: json['last_inspected_at'] != null
          ? DateTime.tryParse(json['last_inspected_at'].toString())
          : null,
      notes: json['notes']?.toString(),
    );
  }

  Battery copyWith({
    String? id,
    String? serialNumber,
    String? batteryType,
    String? status,
    double? healthPercentage,
    String? locationType,
    String? locationName,
    int? cycleCount,
    int? totalCycles,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? manufacturer,
    DateTime? manufactureDate,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    DateTime? lastChargedAt,
    DateTime? lastInspectedAt,
    String? notes,
  }) {
    return Battery(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      batteryType: batteryType ?? this.batteryType,
      status: status ?? this.status,
      healthPercentage: healthPercentage ?? this.healthPercentage,
      locationType: locationType ?? this.locationType,
      locationName: locationName ?? this.locationName,
      cycleCount: cycleCount ?? this.cycleCount,
      totalCycles: totalCycles ?? this.totalCycles,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      manufacturer: manufacturer ?? this.manufacturer,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      lastChargedAt: lastChargedAt ?? this.lastChargedAt,
      lastInspectedAt: lastInspectedAt ?? this.lastInspectedAt,
      notes: notes ?? this.notes,
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
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      batteryId: json['battery_id'].toString(),
      fieldChanged: (json['field_changed'] ?? '').toString(),
      oldValue: json['old_value']?.toString(),
      newValue: json['new_value']?.toString(),
      reason: json['reason']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
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
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      batteryId: json['battery_id'].toString(),
      healthPercentage: (json['health_percentage'] is num)
          ? (json['health_percentage'] as num).toDouble()
          : double.tryParse(json['health_percentage']?.toString() ?? '') ?? 0.0,
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
