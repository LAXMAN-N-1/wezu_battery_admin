class BessUnit {
  final int id;
  final String name;
  final String location;
  final double capacityKwh;
  final double currentChargeKwh;
  final double maxPowerKw;
  final String status;
  final double soc;
  final double soh;
  final double temperatureC;
  final int cycleCount;
  final String? manufacturer;
  final String? modelNumber;
  final String? firmwareVersion;
  final String? installedAt;
  final String? lastMaintenanceAt;

  BessUnit({
    required this.id, required this.name, required this.location,
    required this.capacityKwh, required this.currentChargeKwh,
    required this.maxPowerKw, required this.status, required this.soc,
    required this.soh, required this.temperatureC, required this.cycleCount,
    this.manufacturer, this.modelNumber, this.firmwareVersion,
    this.installedAt, this.lastMaintenanceAt,
  });

  factory BessUnit.fromJson(Map<String, dynamic> json) {
    return BessUnit(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      capacityKwh: (json['capacity_kwh'] is num) ? json['capacity_kwh'].toDouble() : double.tryParse(json['capacity_kwh']?.toString() ?? '0') ?? 0,
      currentChargeKwh: (json['current_charge_kwh'] is num) ? json['current_charge_kwh'].toDouble() : 0,
      maxPowerKw: (json['max_power_kw'] is num) ? json['max_power_kw'].toDouble() : 0,
      status: json['status']?.toString() ?? 'unknown',
      soc: (json['soc'] is num) ? json['soc'].toDouble() : 0,
      soh: (json['soh'] is num) ? json['soh'].toDouble() : 0,
      temperatureC: (json['temperature_c'] is num) ? json['temperature_c'].toDouble() : 0,
      cycleCount: (json['cycle_count'] is int) ? json['cycle_count'] : int.tryParse(json['cycle_count']?.toString() ?? '0') ?? 0,
      manufacturer: json['manufacturer']?.toString(),
      modelNumber: json['model_number']?.toString(),
      firmwareVersion: json['firmware_version']?.toString(),
      installedAt: json['installed_at']?.toString(),
      lastMaintenanceAt: json['last_maintenance_at']?.toString(),
    );
  }
}

class BessEnergyLog {
  final int id;
  final int bessUnitId;
  final String timestamp;
  final double powerKw;
  final double energyKwh;
  final double socStart;
  final double socEnd;
  final String source;

  BessEnergyLog({
    required this.id, required this.bessUnitId, required this.timestamp,
    required this.powerKw, required this.energyKwh, required this.socStart,
    required this.socEnd, required this.source,
  });

  factory BessEnergyLog.fromJson(Map<String, dynamic> json) {
    return BessEnergyLog(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bessUnitId: (json['bess_unit_id'] is int) ? json['bess_unit_id'] : 0,
      timestamp: json['timestamp']?.toString() ?? '',
      powerKw: (json['power_kw'] is num) ? json['power_kw'].toDouble() : 0,
      energyKwh: (json['energy_kwh'] is num) ? json['energy_kwh'].toDouble() : 0,
      socStart: (json['soc_start'] is num) ? json['soc_start'].toDouble() : 0,
      socEnd: (json['soc_end'] is num) ? json['soc_end'].toDouble() : 0,
      source: json['source']?.toString() ?? 'grid',
    );
  }
}

class BessGridEvent {
  final int id;
  final int bessUnitId;
  final String eventType;
  final String status;
  final String startTime;
  final String? endTime;
  final double targetPowerKw;
  final double? actualPowerKw;
  final double? energyKwh;
  final double? revenueEarned;
  final String? gridOperator;
  final String? notes;

  BessGridEvent({
    required this.id, required this.bessUnitId, required this.eventType,
    required this.status, required this.startTime, this.endTime,
    required this.targetPowerKw, this.actualPowerKw, this.energyKwh,
    this.revenueEarned, this.gridOperator, this.notes,
  });

  factory BessGridEvent.fromJson(Map<String, dynamic> json) {
    return BessGridEvent(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bessUnitId: (json['bess_unit_id'] is int) ? json['bess_unit_id'] : 0,
      eventType: json['event_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString(),
      targetPowerKw: (json['target_power_kw'] is num) ? json['target_power_kw'].toDouble() : 0,
      actualPowerKw: (json['actual_power_kw'] is num) ? json['actual_power_kw'].toDouble() : null,
      energyKwh: (json['energy_kwh'] is num) ? json['energy_kwh'].toDouble() : null,
      revenueEarned: (json['revenue_earned'] is num) ? json['revenue_earned'].toDouble() : null,
      gridOperator: json['grid_operator']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class BessReport {
  final int id;
  final int? bessUnitId;
  final String reportType;
  final String periodStart;
  final String periodEnd;
  final double totalChargedKwh;
  final double totalDischargedKwh;
  final double avgEfficiency;
  final double peakPowerKw;
  final double avgSoc;
  final double revenue;
  final double cost;
  final int gridEventsCount;

  BessReport({
    required this.id, this.bessUnitId, required this.reportType,
    required this.periodStart, required this.periodEnd,
    required this.totalChargedKwh, required this.totalDischargedKwh,
    required this.avgEfficiency, required this.peakPowerKw,
    required this.avgSoc, required this.revenue, required this.cost,
    required this.gridEventsCount,
  });

  factory BessReport.fromJson(Map<String, dynamic> json) {
    return BessReport(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bessUnitId: json['bess_unit_id'] != null ? (json['bess_unit_id'] is int ? json['bess_unit_id'] : int.tryParse(json['bess_unit_id'].toString())) : null,
      reportType: json['report_type']?.toString() ?? '',
      periodStart: json['period_start']?.toString() ?? '',
      periodEnd: json['period_end']?.toString() ?? '',
      totalChargedKwh: (json['total_charged_kwh'] is num) ? json['total_charged_kwh'].toDouble() : 0,
      totalDischargedKwh: (json['total_discharged_kwh'] is num) ? json['total_discharged_kwh'].toDouble() : 0,
      avgEfficiency: (json['avg_efficiency'] is num) ? json['avg_efficiency'].toDouble() : 0,
      peakPowerKw: (json['peak_power_kw'] is num) ? json['peak_power_kw'].toDouble() : 0,
      avgSoc: (json['avg_soc'] is num) ? json['avg_soc'].toDouble() : 0,
      revenue: (json['revenue'] is num) ? json['revenue'].toDouble() : 0,
      cost: (json['cost'] is num) ? json['cost'].toDouble() : 0,
      gridEventsCount: (json['grid_events_count'] is int) ? json['grid_events_count'] : 0,
    );
  }
}

class BessOverviewStats {
  final int totalUnits;
  final int onlineUnits;
  final double totalCapacityKwh;
  final double currentStoredKwh;
  final double avgSoc;
  final double avgSoh;
  final double totalEnergyTodayKwh;
  final double totalRevenueToday;

  BessOverviewStats({
    required this.totalUnits, required this.onlineUnits,
    required this.totalCapacityKwh, required this.currentStoredKwh,
    required this.avgSoc, required this.avgSoh,
    required this.totalEnergyTodayKwh, required this.totalRevenueToday,
  });

  factory BessOverviewStats.fromJson(Map<String, dynamic> json) {
    return BessOverviewStats(
      totalUnits: (json['total_units'] is int) ? json['total_units'] : 0,
      onlineUnits: (json['online_units'] is int) ? json['online_units'] : 0,
      totalCapacityKwh: (json['total_capacity_kwh'] is num) ? json['total_capacity_kwh'].toDouble() : 0,
      currentStoredKwh: (json['current_stored_kwh'] is num) ? json['current_stored_kwh'].toDouble() : 0,
      avgSoc: (json['avg_soc'] is num) ? json['avg_soc'].toDouble() : 0,
      avgSoh: (json['avg_soh'] is num) ? json['avg_soh'].toDouble() : 0,
      totalEnergyTodayKwh: (json['total_energy_today_kwh'] is num) ? json['total_energy_today_kwh'].toDouble() : 0,
      totalRevenueToday: (json['total_revenue_today'] is num) ? json['total_revenue_today'].toDouble() : 0,
    );
  }
}
