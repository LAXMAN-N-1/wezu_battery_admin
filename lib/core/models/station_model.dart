enum StationStatus {
  online,
  offline,
  maintenance,
  fault;

  String get label {
    switch (this) {
      case StationStatus.online: return 'Online';
      case StationStatus.offline: return 'Offline';
      case StationStatus.maintenance: return 'Maintenance';
      case StationStatus.fault: return 'Fault';
    }
  }
}

class StationModel {
  final String id;
  final String name;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final StationStatus status;
  final int totalSlots;
  final int availableBatteries;
  final int chargingBatteries;
  final double temperature;
  final double powerUsage;
  final DateTime lastHeartbeat;
  final int emptySlots;
  final int dailySwaps;

  StationModel({
    required this.id,
    required this.name,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.totalSlots,
    required this.availableBatteries,
    required this.chargingBatteries,
    required this.temperature,
    required this.powerUsage,
    required this.lastHeartbeat,
    this.emptySlots = 0,
    this.dailySwaps = 0,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'],
      name: json['name'],
      locationAddress: json['location_address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: StationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StationStatus.offline,
      ),
      totalSlots: json['total_slots'],
      availableBatteries: json['available_batteries'],
      chargingBatteries: json['charging_batteries'],
      temperature: (json['temperature'] as num).toDouble(),
      powerUsage: (json['power_usage'] as num).toDouble(),
      lastHeartbeat: DateTime.parse(json['last_heartbeat']),
      emptySlots: json['empty_slots'] ?? 0,
      dailySwaps: json['daily_swaps'] ?? 0,
    );
  }
}
