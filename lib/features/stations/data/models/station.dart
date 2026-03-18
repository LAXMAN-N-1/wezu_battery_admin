class StationCamera {
  final int id;
  final String name;
  final String streamUrl;
  final bool isOnline;

  const StationCamera({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.isOnline = true,
  });

  factory StationCamera.fromJson(Map<String, dynamic> json) {
    return StationCamera(
      id: _asInt(json['id']),
      name: (json['name'] ?? json['label'] ?? 'Camera').toString(),
      streamUrl: (json['stream_url'] ?? json['streamUrl'] ?? '').toString(),
      isOnline: _asBool(json['is_online'] ?? json['isOnline'], fallback: true),
    );
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
  final int totalSlots;
  final int availableBatteries;
  final int emptySlots;
  final DateTime lastPing;
  final int? capacity;
  final String stationType;
  final double rating;
  final int totalReviews;
  final double? powerRatingKw;
  final String? contactPhone;
  final DateTime createdAt;
  final DateTime? lastHeartbeat;
  final bool is24x7;
  final String? openingHours;
  final List<StationCamera> cameras;

  const Station({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.totalSlots,
    required this.availableBatteries,
    required this.emptySlots,
    required this.lastPing,
    this.capacity,
    this.stationType = 'standard',
    this.rating = 0,
    this.totalReviews = 0,
    this.powerRatingKw,
    this.contactPhone,
    required this.createdAt,
    this.lastHeartbeat,
    this.is24x7 = false,
    this.openingHours,
    this.cameras = const [],
  });

  int get availableSlots {
    if (emptySlots < 0) {
      return 0;
    }
    if (emptySlots > totalSlots) {
      return totalSlots;
    }
    return emptySlots;
  }

  int get resolvedCapacity => capacity ?? totalSlots;

  String get statusDisplay {
    if (status.isEmpty) {
      return 'Offline';
    }

    final normalized = status.replaceAll('_', ' ').trim();
    return normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Station copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? status,
    int? totalSlots,
    int? availableBatteries,
    int? emptySlots,
    DateTime? lastPing,
    int? capacity,
    String? stationType,
    double? rating,
    int? totalReviews,
    double? powerRatingKw,
    String? contactPhone,
    DateTime? createdAt,
    DateTime? lastHeartbeat,
    bool? is24x7,
    String? openingHours,
    List<StationCamera>? cameras,
  }) {
    final nextTotalSlots = totalSlots ?? this.totalSlots;
    final nextAvailableBatteries =
        availableBatteries ?? this.availableBatteries;

    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      totalSlots: nextTotalSlots,
      availableBatteries: nextAvailableBatteries,
      emptySlots: emptySlots ?? (nextTotalSlots - nextAvailableBatteries),
      lastPing: lastPing ?? this.lastPing,
      capacity: capacity ?? this.capacity,
      stationType: stationType ?? this.stationType,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      powerRatingKw: powerRatingKw ?? this.powerRatingKw,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      is24x7: is24x7 ?? this.is24x7,
      openingHours: openingHours ?? this.openingHours,
      cameras: cameras ?? this.cameras,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'total_slots': totalSlots,
      'available_batteries': availableBatteries,
      'empty_slots': emptySlots,
      'capacity': resolvedCapacity,
      'station_type': stationType,
      'rating': rating,
      'total_reviews': totalReviews,
      'power_rating_kw': powerRatingKw,
      'contact_phone': contactPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': lastPing.toIso8601String(),
      'last_heartbeat': lastHeartbeat?.toIso8601String(),
      'is_24x7': is24x7,
      'opening_hours': openingHours,
      'cameras': cameras
          .map(
            (camera) => {
              'id': camera.id,
              'name': camera.name,
              'stream_url': camera.streamUrl,
              'is_online': camera.isOnline,
            },
          )
          .toList(),
    };
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    final totalSlots = _asInt(
      json['total_slots'] ?? json['capacity'] ?? json['slots'],
    );
    final availableBatteries = _asInt(
      json['available_batteries'] ??
          json['available_battery_count'] ??
          json['batteries'],
    );
    final emptySlots = _asInt(
      json['empty_slots'] ?? json['available_slots'],
      fallback: totalSlots - availableBatteries,
    );
    final createdAt = _asDateTime(json['created_at']) ?? DateTime.now();
    final updatedAt =
        _asDateTime(json['updated_at']) ??
        _asDateTime(json['last_ping']) ??
        createdAt;
    final camerasJson = json['cameras'];

    return Station(
      id: _asInt(json['id']),
      name: (json['name'] ?? json['station_name'] ?? 'Unknown Station')
          .toString(),
      address: (json['address'] ?? '').toString(),
      city: _asString(json['city']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      status: (json['status'] ?? 'inactive').toString(),
      totalSlots: totalSlots,
      availableBatteries: availableBatteries,
      emptySlots: emptySlots,
      lastPing: updatedAt,
      capacity: json['capacity'] == null ? null : _asInt(json['capacity']),
      stationType: (json['station_type'] ?? json['type'] ?? 'standard')
          .toString(),
      rating: _asDouble(json['rating']),
      totalReviews: _asInt(json['total_reviews'] ?? json['review_count']),
      powerRatingKw:
          json['power_rating_kw'] == null && json['power_output_kw'] == null
          ? null
          : _asDouble(json['power_rating_kw'] ?? json['power_output_kw']),
      contactPhone: _asString(json['contact_phone'] ?? json['phone']),
      createdAt: createdAt,
      lastHeartbeat:
          _asDateTime(json['last_heartbeat']) ??
          _asDateTime(json['heartbeat_at']) ??
          _asDateTime(json['last_ping']),
      is24x7: _asBool(json['is_24x7'] ?? json['always_open']),
      openingHours: _asString(json['opening_hours']),
      cameras: camerasJson is List
          ? camerasJson
                .whereType<Map<String, dynamic>>()
                .map(StationCamera.fromJson)
                .toList()
          : const [],
    );
  }
}

String? _asString(dynamic value) {
  if (value == null) {
    return null;
  }

  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value == null) {
    return fallback;
  }

  return int.tryParse(value.toString()) ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    return fallback;
  }

  return double.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == '0') {
      return false;
    }
  }
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
