class Battery {
  final int id;
  final String serialNumber;
  final String modelNumber;
  final String status; // 'available', 'rented', 'maintenance', 'retired'
  final double healthPercentage;
  final String locationName;
  final int cycleCount;
  final DateTime lastUpdated;

  Battery({
    required this.id,
    required this.serialNumber,
    required this.modelNumber,
    required this.status,
    required this.healthPercentage,
    required this.locationName,
    required this.cycleCount,
    required this.lastUpdated,
  });

  factory Battery.fromJson(Map<String, dynamic> json) {
    return Battery(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String,
      modelNumber: json['model_number'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      healthPercentage: (json['health_percentage'] as num?)?.toDouble() ?? 100.0,
      locationName: json['location_name'] ?? 'Warehouse',
      cycleCount: json['cycle_count'] ?? 0,
      lastUpdated: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}
