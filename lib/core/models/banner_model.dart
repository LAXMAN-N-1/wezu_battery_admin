enum BannerType {
  promotional,
  informational,
  alert;

  String get label {
    switch (this) {
      case BannerType.promotional: return 'Promotional';
      case BannerType.informational: return 'Informational';
      case BannerType.alert: return 'Alert';
    }
  }
}

class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final BannerType type;
  final bool isActive;
  final String? targetScreen;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.isActive,
    this.targetScreen,
    DateTime? createdAt,
    this.startDate,
    this.endDate,
    this.priority = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      type: BannerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BannerType.promotional,
      ),
      isActive: json['is_active'] ?? true,
      targetScreen: json['target_screen'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    BannerType? type,
    bool? isActive,
    String? targetScreen,
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      targetScreen: targetScreen ?? this.targetScreen,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
    );
  }
}
