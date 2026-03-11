class Transaction {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String type; // 'rental', 'security_deposit', 'refund', 'subscription'
  final String status; // 'success', 'pending', 'failed'
  final DateTime timestamp;

  const Transaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.type,
    required this.status,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      userId: json['wallet_id']?.toString() ?? 'unknown',
      userName: json['description'] ?? "Wallet #${json['wallet_id']}",
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['category'] ?? json['type'] ?? 'other',
      status: json['status'] ?? 'success',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
