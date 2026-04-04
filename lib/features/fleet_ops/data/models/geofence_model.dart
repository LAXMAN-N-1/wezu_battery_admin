class Geofence {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String type;
  final String? polygonCoords;
  final bool isActive;

  Geofence({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.type,
    this.polygonCoords,
    required this.isActive,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toDouble(),
      type: json['type'] ?? 'safe_zone',
      polygonCoords: json['polygon_coords'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'type': type,
      'polygon_coords': polygonCoords,
      'is_active': isActive,
    };
  }
}
