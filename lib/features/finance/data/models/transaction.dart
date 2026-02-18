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
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
