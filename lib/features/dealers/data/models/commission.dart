class CommissionConfig {
  final int id;
  final int? dealerId;
  final String transactionType;
  final double percentage;
  final double flatFee;
  final bool isActive;

  const CommissionConfig({
    required this.id,
    this.dealerId,
    required this.transactionType,
    required this.percentage,
    required this.flatFee,
    required this.isActive,
  });

  factory CommissionConfig.fromJson(Map<String, dynamic> json) {
    return CommissionConfig(
      id: json['id'] as int,
      dealerId: json['dealer_id'],
      transactionType: json['transaction_type'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      flatFee: (json['flat_fee'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class CommissionLog {
  final int id;
  final String dealerName;
  final double amount;
  final String status;
  final DateTime createdAt;

  const CommissionLog({
    required this.id,
    required this.dealerName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory CommissionLog.fromJson(Map<String, dynamic> json) {
    return CommissionLog(
      id: json['id'] as int,
      dealerName: json['dealer_name'] ?? 'Unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
