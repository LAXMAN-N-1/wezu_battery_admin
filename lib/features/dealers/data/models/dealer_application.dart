class DealerApplication {
  final int id;
  final int dealerId;
  final String businessName;
  final String currentStage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DealerApplication({
    required this.id,
    required this.dealerId,
    required this.businessName,
    required this.currentStage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DealerApplication.fromJson(Map<String, dynamic> json) {
    return DealerApplication(
      id: json['id'] as int,
      dealerId: json['dealer_id'] as int,
      businessName: json['business_name'] ?? 'Unknown',
      currentStage: json['current_stage'] ?? 'SUBMITTED',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}
