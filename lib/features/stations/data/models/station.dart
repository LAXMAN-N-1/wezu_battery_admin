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
    return Station(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      totalSlots: json['total_slots'] as int,
      availableBatteries: json['available_batteries'] as int,
      emptySlots: json['empty_slots'] as int,
      lastPing: json['last_ping'] != null
          ? DateTime.parse(json['last_ping'])
          : DateTime.now(),
    );
  }
}
