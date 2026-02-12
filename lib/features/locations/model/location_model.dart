class LocationNode {
  final int id;
  final String name;
  final int? parentId;

  LocationNode({
    required this.id,
    required this.name,
    this.parentId,
  });

  factory LocationNode.fromJson(Map<String, dynamic> json) {
    return LocationNode(
      id: json['id'],
      name: json['name'],
      parentId: json['continent_id'] ?? json['country_id'] ?? json['region_id'] ?? json['city_id'],
    );
  }
}

enum LocationLevel {
  continent,
  country,
  region,
  city,
  zone;

  String get label {
    switch (this) {
      case LocationLevel.continent: return 'Continents';
      case LocationLevel.country: return 'Countries';
      case LocationLevel.region: return 'Regions';
      case LocationLevel.city: return 'Cities';
      case LocationLevel.zone: return 'Zones';
    }
  }

  LocationLevel? get next {
    final index = LocationLevel.values.indexOf(this);
    if (index < LocationLevel.values.length - 1) {
      return LocationLevel.values[index + 1];
    }
    return null;
  }
}
