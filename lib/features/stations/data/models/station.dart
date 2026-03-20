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
  final String? openingHours;
  final bool is24x7;
  final String? imageUrl;
  final DateTime? lastHeartbeat;
  final DateTime createdAt;
  final List<StationCamera> cameras;
  final int? capacity; // Added for backward compatibility with form

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
    this.openingHours,
    this.is24x7 = false,
    this.imageUrl,
    this.lastHeartbeat,
    required this.createdAt,
    this.cameras = const [],
    this.capacity,
  });

  // Alias for backward compatibility
  int get emptySlots => availableSlots;
  DateTime get lastPing => lastHeartbeat ?? createdAt;

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
      openingHours: json['operating_hours'] ?? json['opening_hours'],
      is24x7: json['is_24x7'] ?? false,
      imageUrl: json['image_url'],
      lastHeartbeat: json['last_heartbeat'] != null ? DateTime.parse(json['last_heartbeat']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      cameras: (json['cameras'] as List?)
              ?.map((c) => StationCamera.fromJson(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
      capacity: json['capacity'] ?? json['total_slots'],
    );
  }

  Station copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? status,
    String? stationType,
    int? totalSlots,
    int? availableBatteries,
    int? availableSlots,
    double? powerRatingKw,
    double? rating,
    int? totalReviews,
    String? contactPhone,
    String? openingHours,
    bool? is24x7,
    String? imageUrl,
    DateTime? lastHeartbeat,
    DateTime? createdAt,
    List<StationCamera>? cameras,
    int? capacity,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      stationType: stationType ?? this.stationType,
      totalSlots: totalSlots ?? this.totalSlots,
      availableBatteries: availableBatteries ?? this.availableBatteries,
      availableSlots: availableSlots ?? this.availableSlots,
      powerRatingKw: powerRatingKw ?? this.powerRatingKw,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      contactPhone: contactPhone ?? this.contactPhone,
      openingHours: openingHours ?? this.openingHours,
      is24x7: is24x7 ?? this.is24x7,
      imageUrl: imageUrl ?? this.imageUrl,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      createdAt: createdAt ?? this.createdAt,
      cameras: cameras ?? this.cameras,
      capacity: capacity ?? this.capacity,
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

class StationPerformanceSummary {
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

  const StationPerformanceSummary({
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

  factory StationPerformanceSummary.fromJson(Map<String, dynamic> json) {
    return StationPerformanceSummary(
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

class StationCamera {
  final String id;
  final String name;
  final String streamUrl;
  final String status;

  const StationCamera({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.status = 'active',
  });

  factory StationCamera.fromJson(Map<String, dynamic> json) {
    return StationCamera(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Camera',
      streamUrl: json['stream_url'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
}
