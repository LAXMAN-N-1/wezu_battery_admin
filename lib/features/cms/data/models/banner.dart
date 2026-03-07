class Banner {
  final int id;
  final String title;
  final String imageUrl;
  final String? deepLink;
  final String? externalUrl;
  final int priority;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int clickCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Banner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.deepLink,
    this.externalUrl,
    required this.priority,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.clickCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      deepLink: json['deep_link'],
      externalUrl: json['external_url'],
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      clickCount: json['click_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'deep_link': deepLink,
      'external_url': externalUrl,
      'priority': priority,
      'is_active': isActive,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}
