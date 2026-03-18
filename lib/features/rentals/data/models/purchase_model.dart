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
      id: json['id'] as int,
      userName: json['user_name'] ?? 'Unknown',
      batteryId: json['battery_id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
