int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class PurchaseOrder {
  final int id;
  final String userName;
  final int batteryId;
  final double amount;
  final DateTime timestamp;

  const PurchaseOrder({
    required this.id,
    required this.userName,
    required this.batteryId,
    required this.amount,
    required this.timestamp,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: _asInt(json['id']),
      userName: (json['user_name'] ?? json['customer_name'] ?? 'Unknown')
          .toString(),
      batteryId: _asInt(json['battery_id'] ?? json['battery']?['id']),
      amount: _asDouble(json['amount'] ?? json['total_amount']),
      timestamp: DateTime.tryParse(
            (json['timestamp'] ?? json['created_at'])?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
