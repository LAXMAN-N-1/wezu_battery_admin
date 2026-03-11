// lib/features/battery_health/data/models/health_models.dart

class HealthOverview {
  final double fleetAvgHealth;
  final int goodCount;
  final int fairCount;
  final int poorCount;
  final int criticalCount;
  final double avgDegradationRate;
  final int batteriesNeedingService;
  final int scheduledMaintenanceCount;
  final int totalBatteries;

  HealthOverview({
    required this.fleetAvgHealth,
    required this.goodCount,
    required this.fairCount,
    required this.poorCount,
    required this.criticalCount,
    required this.avgDegradationRate,
    required this.batteriesNeedingService,
    required this.scheduledMaintenanceCount,
    required this.totalBatteries,
  });

  factory HealthOverview.fromJson(Map<String, dynamic> json) {
    return HealthOverview(
      fleetAvgHealth: (json['fleet_avg_health'] as num?)?.toDouble() ?? 0.0,
      goodCount: json['good_count'] ?? 0,
      fairCount: json['fair_count'] ?? 0,
      poorCount: json['poor_count'] ?? 0,
      criticalCount: json['critical_count'] ?? 0,
      avgDegradationRate: (json['avg_degradation_rate'] as num?)?.toDouble() ?? 0.0,
      batteriesNeedingService: json['batteries_needing_service'] ?? 0,
      scheduledMaintenanceCount: json['scheduled_maintenance_count'] ?? 0,
      totalBatteries: json['total_batteries'] ?? 0,
    );
  }
}

class HealthBattery {
  final String id;
  final String serialNumber;
  final String? manufacturer;
  final String? batteryType;
  final String status;
  final double healthPercentage;
  final String healthStatus;
  final double? voltage;
  final double? temperature;
  final double? internalResistance;
  final int? chargeCycles;
  final double degradationRate;
  final String? lastReadingAt;
  final String? lastMaintenanceAt;
  final int? daysSinceMaintenance;

  HealthBattery({
    required this.id,
    required this.serialNumber,
    this.manufacturer,
    this.batteryType,
    required this.status,
    required this.healthPercentage,
    required this.healthStatus,
    this.voltage,
    this.temperature,
    this.internalResistance,
    this.chargeCycles,
    required this.degradationRate,
    this.lastReadingAt,
    this.lastMaintenanceAt,
    this.daysSinceMaintenance,
  });

  factory HealthBattery.fromJson(Map<String, dynamic> json) {
    return HealthBattery(
      id: json['id'] as String,
      serialNumber: json['serial_number'] ?? '',
      manufacturer: json['manufacturer'],
      batteryType: json['battery_type'],
      status: json['status'] ?? 'unknown',
      healthPercentage: (json['health_percentage'] as num?)?.toDouble() ?? 0.0,
      healthStatus: json['health_status'] ?? 'unknown',
      voltage: (json['voltage'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      internalResistance: (json['internal_resistance'] as num?)?.toDouble(),
      chargeCycles: json['charge_cycles'],
      degradationRate: (json['degradation_rate'] as num?)?.toDouble() ?? 0.0,
      lastReadingAt: json['last_reading_at'],
      lastMaintenanceAt: json['last_maintenance_at'],
      daysSinceMaintenance: json['days_since_maintenance'],
    );
  }
}

class HealthSnapshot {
  final int id;
  final double healthPercentage;
  final double? voltage;
  final double? temperature;
  final double? internalResistance;
  final int? chargeCycles;
  final String snapshotType;
  final String recordedAt;

  HealthSnapshot({
    required this.id,
    required this.healthPercentage,
    this.voltage,
    this.temperature,
    this.internalResistance,
    this.chargeCycles,
    required this.snapshotType,
    required this.recordedAt,
  });

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) {
    return HealthSnapshot(
      id: json['id'],
      healthPercentage: (json['health_percentage'] as num).toDouble(),
      voltage: (json['voltage'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      internalResistance: (json['internal_resistance'] as num?)?.toDouble(),
      chargeCycles: json['charge_cycles'],
      snapshotType: json['snapshot_type'] ?? 'manual',
      recordedAt: json['recorded_at'] ?? '',
    );
  }
}

class MaintenanceSchedule {
  final int id;
  final String batteryId;
  final String? batterySerial;
  final String scheduledDate;
  final String maintenanceType;
  final String priority;
  final int? assignedTo;
  final String? assignedToName;
  final String status;
  final String? notes;
  final double? healthBefore;
  final double? healthAfter;
  final String? completedAt;
  final String createdAt;

  MaintenanceSchedule({
    required this.id,
    required this.batteryId,
    this.batterySerial,
    required this.scheduledDate,
    required this.maintenanceType,
    required this.priority,
    this.assignedTo,
    this.assignedToName,
    required this.status,
    this.notes,
    this.healthBefore,
    this.healthAfter,
    this.completedAt,
    required this.createdAt,
  });

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) {
    return MaintenanceSchedule(
      id: json['id'],
      batteryId: json['battery_id'] ?? '',
      batterySerial: json['battery_serial'],
      scheduledDate: json['scheduled_date'] ?? '',
      maintenanceType: json['maintenance_type'] ?? '',
      priority: json['priority'] ?? 'medium',
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      status: json['status'] ?? 'scheduled',
      notes: json['notes'],
      healthBefore: (json['health_before'] as num?)?.toDouble(),
      healthAfter: (json['health_after'] as num?)?.toDouble(),
      completedAt: json['completed_at'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class HealthAlert {
  final int id;
  final String batteryId;
  final String? batterySerial;
  final String alertType;
  final String severity;
  final String message;
  final bool isResolved;
  final int? resolvedBy;
  final String? resolvedAt;
  final String? resolutionReason;
  final String createdAt;

  HealthAlert({
    required this.id,
    required this.batteryId,
    this.batterySerial,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionReason,
    required this.createdAt,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id: json['id'],
      batteryId: json['battery_id'] ?? '',
      batterySerial: json['battery_serial'],
      alertType: json['alert_type'] ?? '',
      severity: json['severity'] ?? 'info',
      message: json['message'] ?? '',
      isResolved: json['is_resolved'] ?? false,
      resolvedBy: json['resolved_by'],
      resolvedAt: json['resolved_at'],
      resolutionReason: json['resolution_reason'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class HealthBatteryDetail {
  final String id;
  final String serialNumber;
  final String? manufacturer;
  final String? batteryType;
  final String status;
  final double healthPercentage;
  final String healthStatus;

  // Telemetry
  final double? voltage;
  final double? temperature;
  final double? internalResistance;
  final int? chargeCycles;
  final int totalCycles;
  final int cycleCount;

  // Computed
  final double degradationRate;
  final String? predictedEolDate;
  final String? predictedFairDate;
  final int? estimatedRemainingCycles;
  final double? estimatedRemainingYears;

  // Health breakdown
  final double voltageHealth;
  final double temperatureHealth;
  final double resistanceHealth;
  final double cycleHealth;

  // History
  final List<HealthSnapshot> snapshots;
  final List<MaintenanceSchedule> maintenanceHistory;
  final List<HealthAlert> activeAlerts;

  // Stats
  final double? minHealth;
  final double? maxHealth;
  final double? avgHealth;
  final double? fastestDrop;
  final String? fastestDropWeek;

  final String? warrantyExpiry;
  final String? lastMaintenanceAt;
  final String? createdAt;

  HealthBatteryDetail({
    required this.id,
    required this.serialNumber,
    this.manufacturer,
    this.batteryType,
    required this.status,
    required this.healthPercentage,
    required this.healthStatus,
    this.voltage,
    this.temperature,
    this.internalResistance,
    this.chargeCycles,
    this.totalCycles = 0,
    this.cycleCount = 0,
    required this.degradationRate,
    this.predictedEolDate,
    this.predictedFairDate,
    this.estimatedRemainingCycles,
    this.estimatedRemainingYears,
    this.voltageHealth = 100,
    this.temperatureHealth = 100,
    this.resistanceHealth = 100,
    this.cycleHealth = 100,
    this.snapshots = const [],
    this.maintenanceHistory = const [],
    this.activeAlerts = const [],
    this.minHealth,
    this.maxHealth,
    this.avgHealth,
    this.fastestDrop,
    this.fastestDropWeek,
    this.warrantyExpiry,
    this.lastMaintenanceAt,
    this.createdAt,
  });

  factory HealthBatteryDetail.fromJson(Map<String, dynamic> json) {
    return HealthBatteryDetail(
      id: json['id'] as String,
      serialNumber: json['serial_number'] ?? '',
      manufacturer: json['manufacturer'],
      batteryType: json['battery_type'],
      status: json['status'] ?? 'unknown',
      healthPercentage: (json['health_percentage'] as num?)?.toDouble() ?? 0.0,
      healthStatus: json['health_status'] ?? 'unknown',
      voltage: (json['voltage'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      internalResistance: (json['internal_resistance'] as num?)?.toDouble(),
      chargeCycles: json['charge_cycles'],
      totalCycles: json['total_cycles'] ?? 0,
      cycleCount: json['cycle_count'] ?? 0,
      degradationRate: (json['degradation_rate'] as num?)?.toDouble() ?? 0.0,
      predictedEolDate: json['predicted_eol_date'],
      predictedFairDate: json['predicted_fair_date'],
      estimatedRemainingCycles: json['estimated_remaining_cycles'],
      estimatedRemainingYears: (json['estimated_remaining_years'] as num?)?.toDouble(),
      voltageHealth: (json['voltage_health'] as num?)?.toDouble() ?? 100,
      temperatureHealth: (json['temperature_health'] as num?)?.toDouble() ?? 100,
      resistanceHealth: (json['resistance_health'] as num?)?.toDouble() ?? 100,
      cycleHealth: (json['cycle_health'] as num?)?.toDouble() ?? 100,
      snapshots: (json['snapshots'] as List<dynamic>?)
              ?.map((s) => HealthSnapshot.fromJson(s))
              .toList() ??
          [],
      maintenanceHistory: (json['maintenance_history'] as List<dynamic>?)
              ?.map((m) => MaintenanceSchedule.fromJson(m))
              .toList() ??
          [],
      activeAlerts: (json['active_alerts'] as List<dynamic>?)
              ?.map((a) => HealthAlert.fromJson(a))
              .toList() ??
          [],
      minHealth: (json['min_health'] as num?)?.toDouble(),
      maxHealth: (json['max_health'] as num?)?.toDouble(),
      avgHealth: (json['avg_health'] as num?)?.toDouble(),
      fastestDrop: (json['fastest_drop'] as num?)?.toDouble(),
      fastestDropWeek: json['fastest_drop_week'],
      warrantyExpiry: json['warranty_expiry'],
      lastMaintenanceAt: json['last_maintenance_at'],
      createdAt: json['created_at'],
    );
  }
}

class FleetHealthTrendPoint {
  final String date;
  final double avgHealth;

  FleetHealthTrendPoint({required this.date, required this.avgHealth});

  factory FleetHealthTrendPoint.fromJson(Map<String, dynamic> json) {
    return FleetHealthTrendPoint(
      date: json['date'] ?? '',
      avgHealth: (json['avg_health'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WorstDegrader {
  final String batteryId;
  final String serialNumber;
  final double degradationRate;
  final double currentHealth;

  WorstDegrader({
    required this.batteryId,
    required this.serialNumber,
    required this.degradationRate,
    required this.currentHealth,
  });

  factory WorstDegrader.fromJson(Map<String, dynamic> json) {
    return WorstDegrader(
      batteryId: json['battery_id'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      degradationRate: (json['degradation_rate'] as num?)?.toDouble() ?? 0.0,
      currentHealth: (json['current_health'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HealthAnalytics {
  final List<FleetHealthTrendPoint> fleetTrend;
  final Map<String, int> healthDistribution;
  final List<WorstDegrader> worstDegraders;
  final double maintenanceComplianceRate;

  HealthAnalytics({
    required this.fleetTrend,
    required this.healthDistribution,
    required this.worstDegraders,
    required this.maintenanceComplianceRate,
  });

  factory HealthAnalytics.fromJson(Map<String, dynamic> json) {
    return HealthAnalytics(
      fleetTrend: (json['fleet_trend'] as List<dynamic>?)
              ?.map((t) => FleetHealthTrendPoint.fromJson(t))
              .toList() ??
          [],
      healthDistribution: (json['health_distribution'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      worstDegraders: (json['worst_degraders'] as List<dynamic>?)
              ?.map((w) => WorstDegrader.fromJson(w))
              .toList() ??
          [],
      maintenanceComplianceRate:
          (json['maintenance_compliance_rate'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
