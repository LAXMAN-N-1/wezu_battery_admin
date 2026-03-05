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
  final String? contactPhone;
  final String? contactEmail;
  final int? capacity;
  final String? openingHours;

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
    this.contactPhone,
    this.contactEmail,
    this.capacity,
    this.openingHours,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    // Map backend status to frontend status
    String mappedStatus = json['status'] as String? ?? 'active';
    if (mappedStatus == 'operational') mappedStatus = 'active';
    if (mappedStatus == 'closed') mappedStatus = 'inactive';

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
      openingHours:
          (json['opening_hours'] ?? json['operating_hours']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Map frontend status to backend status
    String backendStatus = status;
    if (backendStatus == 'active') backendStatus = 'operational';
    if (backendStatus == 'inactive') backendStatus = 'closed';

    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': backendStatus,
      'total_slots': totalSlots,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      // For Create, backend schema uses opening_hours
      'opening_hours': openingHours,
      // For Update, backend schema uses operating_hours (adding both for safety)
      'operating_hours': openingHours,
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
    );
  }
}
