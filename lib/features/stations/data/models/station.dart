import 'dart:convert';

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
  final int emptySlots;
  final DateTime lastPing;
  final String? contactPhone;
  final String? contactEmail;
  final int? capacity;
  final String? openingHours;
  final bool is24x7;
  final List<StationCamera> cameras;

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
    required this.emptySlots,
    required this.lastPing,
    this.contactPhone,
    this.contactEmail,
    this.capacity,
    this.openingHours,
    this.is24x7 = false,
    this.cameras = const [],
  });

  // Alias for backward compatibility
  int get availableSlots => emptySlots;

  factory Station.fromJson(Map<String, dynamic> json) {
    // Map backend status to frontend status
    String rawStatus = (json['status'] as String? ?? 'active').toLowerCase();
    String mappedStatus = rawStatus;
    if (rawStatus == 'operational' || rawStatus == 'online') mappedStatus = 'active';
    if (rawStatus == 'closed' || rawStatus == 'inactive') mappedStatus = 'inactive';
    if (rawStatus == 'error' || rawStatus == 'offline') mappedStatus = 'inactive';

    return Station(
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
      openingHours: json['opening_hours'] != null
          ? (json['opening_hours'] is String
              ? json['opening_hours'] as String
              : jsonEncode(json['opening_hours']))
          : (json['operating_hours'] != null
              ? (json['operating_hours'] is String
                  ? json['operating_hours'] as String
                  : jsonEncode(json['operating_hours']))
              : null),
      is24x7: json['is_24x7'] as bool? ?? false,
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
      'is_24x7': is24x7,
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
    bool? is24x7,
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
      is24x7: is24x7 ?? this.is24x7,
      cameras: cameras ?? this.cameras,
    );
  }
}
