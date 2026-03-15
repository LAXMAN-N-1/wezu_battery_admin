class Station {
  final int id;
  final String name;
  final String address;
  final String? city;
  final double latitude;
  final double longitude;
  final String status;
  final String stationType;
  final int totalSlots;
  final int availableBatteries;
  final int availableSlots;
  final double? powerRatingKw;
  final double rating;
  final int totalReviews;
  final String? contactPhone;
  final String? operatingHours;
  final bool is24x7;
  final String? imageUrl;
  final DateTime? lastHeartbeat;
  final DateTime createdAt;

  const Station({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.stationType = 'automated',
    required this.totalSlots,
    required this.availableBatteries,
    required this.availableSlots,
    this.powerRatingKw,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.contactPhone,
    this.operatingHours,
    this.is24x7 = false,
    this.imageUrl,
    this.lastHeartbeat,
    required this.createdAt,
  });

  // Alias for backward compatibility
  int get emptySlots => availableSlots;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'OPERATIONAL',
      stationType: json['station_type'] ?? 'automated',
      totalSlots: json['total_slots'] ?? 0,
      availableBatteries: json['available_batteries'] ?? 0,
      availableSlots: json['available_slots'] ?? json['empty_slots'] ?? 0,
      powerRatingKw: (json['power_rating_kw'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      contactPhone: json['contact_phone'],
      operatingHours: json['operating_hours'],
      is24x7: json['is_24x7'] ?? false,
      imageUrl: json['image_url'],
      lastHeartbeat: json['last_heartbeat'] != null ? DateTime.parse(json['last_heartbeat']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL': return 'Operational';
      case 'MAINTENANCE': return 'Maintenance';
      case 'CLOSED': return 'Closed';
      case 'ERROR': return 'Error';
      case 'OFFLINE': return 'Offline';
      default: return status;
    }
  }
}

class StationPerformance {
  final int stationId;
  final String stationName;
  final String? city;
  final String status;
  final double utilizationPercentage;
  final int totalSlots;
  final int occupiedSlots;
  final int availableBatteries;
  final double rating;
  final int totalReviews;
  final double? powerRatingKw;

  const StationPerformance({
    required this.stationId,
    required this.stationName,
    this.city,
    required this.status,
    required this.utilizationPercentage,
    required this.totalSlots,
    required this.occupiedSlots,
    required this.availableBatteries,
    required this.rating,
    required this.totalReviews,
    this.powerRatingKw,
  });

  factory StationPerformance.fromJson(Map<String, dynamic> json) {
    return StationPerformance(
      stationId: json['station_id'] as int,
      stationName: json['station_name'] ?? '',
      city: json['city'],
      status: json['status'] ?? '',
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
      totalSlots: json['total_slots'] ?? 0,
      occupiedSlots: json['occupied_slots'] ?? 0,
      availableBatteries: json['available_batteries'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      powerRatingKw: (json['power_rating_kw'] as num?)?.toDouble(),
    );
  }
}
