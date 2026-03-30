class AdminGroupModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminGroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminGroupModel.fromJson(Map<String, dynamic> json) {
    return AdminGroupModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}
