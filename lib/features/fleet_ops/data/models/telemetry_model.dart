class TelemetryData {
  final int id;
  final String deviceId;
  final int? batteryId;
  final double? latitude;
  final double? longitude;
  final double? speedKmph;
  final double? voltage;
  final double? current;
  final double? temperature;
  final double? soc;
  final DateTime timestamp;

  TelemetryData({
    required this.id,
    required this.deviceId,
    this.batteryId,
    this.latitude,
    this.longitude,
    this.speedKmph,
    this.voltage,
    this.current,
    this.temperature,
    this.soc,
    required this.timestamp,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      id: json['id'],
      deviceId: json['device_id'],
      batteryId: json['battery_id'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      speedKmph: json['speed_kmph'] != null ? (json['speed_kmph'] as num).toDouble() : null,
      voltage: json['voltage'] != null ? (json['voltage'] as num).toDouble() : null,
      current: json['current'] != null ? (json['current'] as num).toDouble() : null,
      temperature: json['temperature'] != null ? (json['temperature'] as num).toDouble() : null,
      soc: json['soc'] != null ? (json['soc'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
