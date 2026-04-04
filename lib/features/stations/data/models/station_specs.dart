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
    'power_kw': powerKw,
    'charging_speed_kmh': chargingSpeedKmh,
    'efficiency_percent': efficiencyPercent,
    'count': count,
  };

  factory ChargerConfig.fromJson(Map<String, dynamic> json) => ChargerConfig(
    type: ChargerTypeX.fromString(json['type'] as String? ?? 'standard'),
    powerKw: (json['power_kw'] as num?)?.toDouble() ?? 0.0,
    chargingSpeedKmh: (json['charging_speed_kmh'] as num?)?.toDouble() ?? 0.0,
    efficiencyPercent: (json['efficiency_percent'] as num?)?.toDouble() ?? 0.0,
    count: json['count'] as int? ?? 0,
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
    'station_id': stationId,
    'max_capacity': maxBatteryCapacity,
    'chargers': chargers.map((c) => c.toJson()).toList(),
    'safety_features': safetyFeatures,
    'min_temp_c': minTempC,
    'max_temp_c': maxTempC,
    'photo_urls': photoUrls,
  };

  factory StationSpecs.fromJson(Map<String, dynamic> json) => StationSpecs(
    stationId: json['station_id'] as int? ?? 0,
    maxBatteryCapacity: json['max_capacity'] as int? ?? 20,
    chargers: (json['chargers'] as List<dynamic>?)
            ?.map((e) => ChargerConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    safetyFeatures: json['safety_features'] is List 
        ? List<String>.from(json['safety_features'] as List)
        : [],
    minTempC: (json['min_temp_c'] as num?)?.toDouble() ?? 0.0,
    maxTempC: (json['max_temp_c'] as num?)?.toDouble() ?? 45.0,
    photoUrls: json['photo_urls'] is List
        ? List<String>.from(json['photo_urls'] as List)
        : [],
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
