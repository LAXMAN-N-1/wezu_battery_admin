class BatterySpecModel {
  final int id;
  final String name;
  final String brand;
  final String? model;
  final double voltage;
  final double? capacityMah;
  final double? capacityAh;
  final double? weightKg;
  final String? dimensions;
  final String? batteryType;
  final int? cycleLifeExpectancy;
  final String? description;
  final String? imageUrl;
  final int? warrantyMonths;
  final double priceFullPurchase;
  final double pricePerDay;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BatterySpecModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.voltage,
    required this.priceFullPurchase,
    required this.pricePerDay,
    required this.isActive,
    this.model,
    this.capacityMah,
    this.capacityAh,
    this.weightKg,
    this.dimensions,
    this.batteryType,
    this.cycleLifeExpectancy,
    this.description,
    this.imageUrl,
    this.warrantyMonths,
    this.createdAt,
    this.updatedAt,
  });

  factory BatterySpecModel.fromJson(Map<String, dynamic> json) {
    return BatterySpecModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString(),
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      capacityMah: (json['capacity_mah'] as num?)?.toDouble(),
      capacityAh: (json['capacity_ah'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      dimensions: json['dimensions']?.toString(),
      batteryType: json['battery_type']?.toString(),
      cycleLifeExpectancy: (json['cycle_life_expectancy'] as num?)?.toInt(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      warrantyMonths: (json['warranty_months'] as num?)?.toInt(),
      priceFullPurchase: (json['price_full_purchase'] as num?)?.toDouble() ?? 0,
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] == true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class BatteryBatchModel {
  final int id;
  final int specId;
  final String batchNumber;
  final String? purchaseOrderRef;
  final int quantity;
  final DateTime? manufacturerDate;
  final DateTime? createdAt;

  const BatteryBatchModel({
    required this.id,
    required this.specId,
    required this.batchNumber,
    required this.quantity,
    this.purchaseOrderRef,
    this.manufacturerDate,
    this.createdAt,
  });

  factory BatteryBatchModel.fromJson(Map<String, dynamic> json) {
    return BatteryBatchModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      specId: (json['spec_id'] as num?)?.toInt() ?? 0,
      batchNumber: json['batch_number']?.toString() ?? '',
      purchaseOrderRef: json['purchase_order_ref']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      manufacturerDate: BatterySpecModel._parseDate(json['manufacturer_date']),
      createdAt: BatterySpecModel._parseDate(json['created_at']),
    );
  }
}
