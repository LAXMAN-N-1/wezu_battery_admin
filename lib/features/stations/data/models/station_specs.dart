// Charger types supported by the platform
enum ChargerType { fast, standard, solar, supercharger }

extension ChargerTypeX on ChargerType {
  String get label {
    switch (this) {
      case ChargerType.fast:
        return 'Fast Charger';
      case ChargerType.standard:
        return 'Standard';
      case ChargerType.solar:
        return 'Solar';
      case ChargerType.supercharger:
        return 'Supercharger';
    }
  }

  String get icon {
    switch (this) {
      case ChargerType.fast:
        return '⚡';
      case ChargerType.standard:
        return '🔌';
      case ChargerType.solar:
        return '☀️';
      case ChargerType.supercharger:
        return '🚀';
    }
  }

  static ChargerType fromString(String s) {
    return ChargerType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ChargerType.standard,
    );
  }
}

// =============================================================
// ChargerConfig — one row in the charger table
// =============================================================
class ChargerConfig {
  final ChargerType type;
  final double powerKw; // Power requirement in kW
  final double chargingSpeedKmh; // km of range added per hour
  final double efficiencyPercent; // 0–100
  final int count; // Number of units of this charger type

  const ChargerConfig({
    required this.type,
    required this.powerKw,
    required this.chargingSpeedKmh,
    required this.efficiencyPercent,
    required this.count,
  });

  // Total power consumption contributed by this charger config
  double get totalPowerKw => powerKw * count;

  ChargerConfig copyWith({
    ChargerType? type,
    double? powerKw,
    double? chargingSpeedKmh,
    double? efficiencyPercent,
    int? count,
  }) => ChargerConfig(
    type: type ?? this.type,
    powerKw: powerKw ?? this.powerKw,
    chargingSpeedKmh: chargingSpeedKmh ?? this.chargingSpeedKmh,
    efficiencyPercent: efficiencyPercent ?? this.efficiencyPercent,
    count: count ?? this.count,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'powerKw': powerKw,
    'chargingSpeedKmh': chargingSpeedKmh,
    'efficiencyPercent': efficiencyPercent,
    'count': count,
  };

  factory ChargerConfig.fromJson(Map<String, dynamic> json) => ChargerConfig(
    type: ChargerTypeX.fromString(json['type'] as String),
    powerKw: (json['powerKw'] as num).toDouble(),
    chargingSpeedKmh: (json['chargingSpeedKmh'] as num).toDouble(),
    efficiencyPercent: (json['efficiencyPercent'] as num).toDouble(),
    count: json['count'] as int,
  );
}

// Predefined safety features for the checklist
const List<String> kSafetyFeatureOptions = [
  'CCTV Surveillance',
  'Fire Suppression System',
  'Ground Fault Protection',
  'Emergency Stop Button',
  'Smoke Detector',
  'Flood Sensor',
  'Access Control',
  'Lightning Protection',
  'UPS Backup Power',
  'Intruder Alarm',
];

// =============================================================
// StationSpecs — the full specification record for a station
// =============================================================
class StationSpecs {
  final int stationId;
  final int maxBatteryCapacity; // Max batteries storable
  final List<ChargerConfig> chargers;
  final List<String> safetyFeatures; // Selected from kSafetyFeatureOptions
  final double minTempC; // Operating temperature range
  final double maxTempC;
  final List<String> photoUrls; // Placeholder for photos

  const StationSpecs({
    required this.stationId,
    required this.maxBatteryCapacity,
    required this.chargers,
    required this.safetyFeatures,
    required this.minTempC,
    required this.maxTempC,
    required this.photoUrls,
  });

  // Real-time total power consumption across all charger types
  double get totalPowerConsumptionKw =>
      chargers.fold(0.0, (sum, c) => sum + c.totalPowerKw);

  StationSpecs copyWith({
    int? maxBatteryCapacity,
    List<ChargerConfig>? chargers,
    List<String>? safetyFeatures,
    double? minTempC,
    double? maxTempC,
    List<String>? photoUrls,
  }) => StationSpecs(
    stationId: stationId,
    maxBatteryCapacity: maxBatteryCapacity ?? this.maxBatteryCapacity,
    chargers: chargers ?? this.chargers,
    safetyFeatures: safetyFeatures ?? this.safetyFeatures,
    minTempC: minTempC ?? this.minTempC,
    maxTempC: maxTempC ?? this.maxTempC,
    photoUrls: photoUrls ?? this.photoUrls,
  );

  Map<String, dynamic> toJson() => {
    'stationId': stationId,
    'maxBatteryCapacity': maxBatteryCapacity,
    'chargers': chargers.map((c) => c.toJson()).toList(),
    'safetyFeatures': safetyFeatures,
    'minTempC': minTempC,
    'maxTempC': maxTempC,
    'photoUrls': photoUrls,
  };

  factory StationSpecs.fromJson(Map<String, dynamic> json) => StationSpecs(
    stationId: json['stationId'] as int,
    maxBatteryCapacity: json['maxBatteryCapacity'] as int,
    chargers: (json['chargers'] as List<dynamic>)
        .map((e) => ChargerConfig.fromJson(e as Map<String, dynamic>))
        .toList(),
    safetyFeatures: List<String>.from(json['safetyFeatures'] as List),
    minTempC: (json['minTempC'] as num).toDouble(),
    maxTempC: (json['maxTempC'] as num).toDouble(),
    photoUrls: List<String>.from(json['photoUrls'] as List),
  );

  // Default specs for a new station
  factory StationSpecs.defaults(int stationId) => StationSpecs(
    stationId: stationId,
    maxBatteryCapacity: 20,
    chargers: const [
      ChargerConfig(
        type: ChargerType.standard,
        powerKw: 7.4,
        chargingSpeedKmh: 40,
        efficiencyPercent: 85,
        count: 4,
      ),
    ],
    safetyFeatures: const ['CCTV Surveillance', 'Emergency Stop Button'],
    minTempC: 0,
    maxTempC: 45,
    photoUrls: const [],
  );
}
