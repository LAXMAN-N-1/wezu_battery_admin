class Station {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String status; // 'active', 'inactive', 'maintenance'
  final int totalSlots;
  final int availableBatteries;
  final int emptySlots;
  final DateTime lastPing;

  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.totalSlots,
    required this.availableBatteries,
    required this.emptySlots,
    required this.lastPing,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    final total = json['total_slots'] ?? 0;
    final available = json['available_batteries'] ?? 0;
    
    return Station(
      id: json['id'] as int,
      name: json['name'] ?? 'Unknown Station',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'inactive',
      totalSlots: total,
      availableBatteries: available,
      emptySlots: json['empty_slots'] ?? (total - available),
      lastPing: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['last_ping'] != null ? DateTime.parse(json['last_ping']) : DateTime.now()),
    );
  }
}
