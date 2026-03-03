enum BatteryStatus {
  ready,
  charging,
  maintenance,
  inUse,
  inStation;

  String get label {
    switch (this) {
      case BatteryStatus.ready: return 'Ready';
      case BatteryStatus.charging: return 'Charging';
      case BatteryStatus.maintenance: return 'Maintenance';
      case BatteryStatus.inUse: return 'In Use';
      case BatteryStatus.inStation: return 'In Station';
    }
  }
}

class BatteryModel {
  final String id;
  final String serialNumber;
  final String type; // e.g., "Li-ion 2kWh"
  final double health; // 0.0 to 100.0
  final int cycles;
  final BatteryStatus status;
  final String? assignedStationId;
  final String? assignedUserId;
  final double chargeLevel; // 0.0 to 100.0

  BatteryModel({
    required this.id,
    required this.serialNumber,
    required this.type,
    required this.health,
    required this.cycles,
    required this.status,
    this.assignedStationId,
    this.assignedUserId,
    required this.chargeLevel,
  });

  factory BatteryModel.fromJson(Map<String, dynamic> json) {
    return BatteryModel(
      id: json['id'],
      serialNumber: json['serial_number'],
      type: json['type'],
      health: (json['health'] as num).toDouble(),
      cycles: json['cycles'],
      status: BatteryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BatteryStatus.maintenance,
      ),
      assignedStationId: json['assigned_station_id'],
      assignedUserId: json['assigned_user_id'],
      chargeLevel: (json['charge_level'] as num).toDouble(),
    );
  }

  // Compatibility getters
  int get cycleCount => cycles;
  String? get currentStationId => assignedStationId;
  String? get currentUserId => assignedUserId;
}
