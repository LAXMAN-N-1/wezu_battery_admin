
class StationCamera {
  final int id;
  final String name;
  final String streamUrl;
  final bool isActive;

  const StationCamera({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.isActive,
  });

  factory StationCamera.fromJson(Map<String, dynamic> json) {
    return StationCamera(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Camera',
      streamUrl: json['stream_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'is_active': isActive,
    };
  }
}

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
<<<<<<< HEAD
  final int emptySlots;
  final DateTime lastPing;
  final String? contactPhone;
  final String? contactEmail;
  final int? capacity;
  final String? openingHours;
  final List<StationCamera> cameras;
=======
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
>>>>>>> origin/main

  Station({
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
<<<<<<< HEAD
    required this.emptySlots,
    required this.lastPing,
    this.contactPhone,
    this.contactEmail,
    this.capacity,
    this.openingHours,
    this.cameras = const [],
=======
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
>>>>>>> origin/main
  });

  // Alias for backward compatibility
  int get emptySlots => availableSlots;

  factory Station.fromJson(Map<String, dynamic> json) {
    // Map backend status to frontend status
    String rawStatus = (json['status'] as String? ?? 'active').toLowerCase();
    String mappedStatus = rawStatus;
    if (rawStatus == 'operational' || rawStatus == 'online') mappedStatus = 'active';
    if (rawStatus == 'closed' || rawStatus == 'inactive') mappedStatus = 'inactive';
    if (rawStatus == 'error' || rawStatus == 'offline') mappedStatus = 'inactive';

    return Station(
<<<<<<< HEAD
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      status: mappedStatus,
      totalSlots: json['total_slots'] as int? ?? 0,
      availableBatteries: json['available_batteries'] as int? ?? 0,
      emptySlots:
          (json['total_slots'] as int? ?? 0) -
          (json['available_batteries'] as int? ?? 0),
      lastPing: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      capacity: json['total_slots'] as int?,
      // Backend uses opening_hours in GET but operating_hours in some schemas
      openingHours:
          (json['opening_hours'] ?? json['operating_hours']) as String?,
      cameras: json['cameras'] != null
          ? (json['cameras'] as List).map((c) => StationCamera.fromJson(c as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    // Map frontend status to backend status
    // StationUpdate schema and defaults suggest lowercase 'active', 'inactive', 'maintenance'
    String backendStatus = status.toLowerCase();
    if (backendStatus == 'active') backendStatus = 'active'; // Default in StationResponse
    
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': backendStatus,
      'total_slots': totalSlots,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'opening_hours': openingHours,
    };
  }

  Station copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? status,
    int? totalSlots,
    int? availableBatteries,
    int? emptySlots,
    DateTime? lastPing,
    String? contactPhone,
    String? contactEmail,
    int? capacity,
    String? openingHours,
    List<StationCamera>? cameras,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      totalSlots: totalSlots ?? this.totalSlots,
      availableBatteries: availableBatteries ?? this.availableBatteries,
      emptySlots:
          emptySlots ??
          (totalSlots != null || availableBatteries != null
              ? (totalSlots ?? this.totalSlots) -
                    (availableBatteries ?? this.availableBatteries)
              : this.emptySlots),
      lastPing: lastPing ?? this.lastPing,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      capacity: capacity ?? this.capacity,
      openingHours: openingHours ?? this.openingHours,
      cameras: cameras ?? this.cameras,
=======
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
>>>>>>> origin/main
    );
  }
}
