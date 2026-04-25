class DeliveryOrderModel {
  final String id;
  final String orderType;
  final String status;
  final String originAddress;
  final String? destinationAddress;
  final int? assignedDriverId;
  final String driverName;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool otpVerified;
  final DateTime? createdAt;
  
  // New Full Details
  final String priority;
  final int units;
  final String customerName;
  final String? customerPhone;
  final double totalValue;
  final String? trackingNumber;
  final String? proofOfDeliveryUrl;
  final String? proofOfDeliveryNotes;
  final String? notes;
  final List<String> assignedBatteryIds;

  const DeliveryOrderModel({
    required this.id,
    required this.orderType,
    required this.status,
    required this.originAddress,
    this.destinationAddress,
    this.assignedDriverId,
    required this.driverName,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.otpVerified = false,
    this.createdAt,
    this.priority = 'normal',
    this.units = 1,
    this.customerName = 'Unknown',
    this.customerPhone,
    this.totalValue = 0.0,
    this.trackingNumber,
    this.proofOfDeliveryUrl,
    this.proofOfDeliveryNotes,
    this.notes,
    this.assignedBatteryIds = const [],
  });

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderModel(
      id: json['id']?.toString() ?? '',
      orderType: json['order_type']?.toString() ?? 'customer_delivery',
      status: json['status']?.toString() ?? 'pending',
      originAddress: json['origin_address']?.toString() ?? 'Warehouse',
      destinationAddress: json['destination_address']?.toString(),
      assignedDriverId: json['assigned_driver_id'] != null 
          ? int.tryParse(json['assigned_driver_id'].toString()) 
          : null,
      driverName: json['driver_name']?.toString() ?? 'Unassigned',
      scheduledAt: _parseDateTime(json['scheduled_at']),
      startedAt: _parseDateTime(json['started_at']),
      completedAt: _parseDateTime(json['completed_at']),
      otpVerified: json['otp_verified'] == true || json['otp_verified'] == 'true',
      createdAt: _parseDateTime(json['created_at']),
      priority: json['priority']?.toString() ?? 'normal',
      units: _parseInt(json['units']) ?? 1,
      customerName: json['customer_name']?.toString() ?? 'Unknown',
      customerPhone: json['customer_phone']?.toString(),
      totalValue: _parseDouble(json['total_value']) ?? 0.0,
      trackingNumber: json['tracking_number']?.toString(),
      proofOfDeliveryUrl: json['proof_of_delivery_url']?.toString(),
      proofOfDeliveryNotes: json['proof_of_delivery_notes']?.toString(),
      notes: json['notes']?.toString(),
      assignedBatteryIds: _parseStringList(json['assigned_battery_ids']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
