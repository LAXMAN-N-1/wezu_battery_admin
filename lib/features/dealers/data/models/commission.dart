class CommissionConfig {
  final int id;
  final int? dealerId;
  final String? dealerName;
  final String transactionType;
  final double percentage;
  final double flatFee;
  final bool isActive;
  final DateTime? effectiveFrom;

  const CommissionConfig({
    required this.id,
    this.dealerId,
    this.dealerName,
    required this.transactionType,
    required this.percentage,
    required this.flatFee,
    required this.isActive,
    this.effectiveFrom,
  });

  factory CommissionConfig.fromJson(Map<String, dynamic> json) {
    return CommissionConfig(
      id: json['id'] as int,
      dealerId: json['dealer_id'],
      dealerName: json['dealer_name'],
      transactionType: json['transaction_type'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      flatFee: (json['flat_fee'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.tryParse(json['effective_from'])
          : null,
    );
  }
}

class CommissionLog {
  final int id;
  final String dealerName;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const CommissionLog({
    required this.id,
    required this.dealerName,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  factory CommissionLog.fromJson(Map<String, dynamic> json) {
    final dealerId = json['dealer_id'];
    return CommissionLog(
      id: json['id'] as int,
      dealerName:
          json['dealer_name'] ??
          (dealerId != null ? 'Dealer User #$dealerId' : 'Unknown'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
