class LocationNode {
  final int id;
  final String name;
  final int? parentId;
  final List<LocationNode> children;
  final LocationLevel type;

  LocationNode({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
    this.type = LocationLevel.area,
  });

  factory LocationNode.fromJson(Map<String, dynamic> json) {
    return LocationNode(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => LocationNode.fromJson(e))
              .toList() ??
          [],
      type: LocationLevel.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LocationLevel.area,
      ),
    );
  }

  LocationLevel? get next => type.next;
}

enum LocationLevel {
  continent,
  country,
  region,
  city,
  area;
  LocationLevel? get next {
    final index = this.index;
    if (index < LocationLevel.values.length - 1) {
      return LocationLevel.values[index + 1];
    }
    return null;
  }
}
