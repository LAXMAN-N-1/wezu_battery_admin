class Banner {
  final int id;
  final String title;
  final String imageUrl;
  final String type; // Home Carousel | Popup | Top Notification | Floating Card
  final String targetAudience; // All Users | New Users | Premium | Specific City
  final String? ctaText;
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
    this.type = 'Home Carousel',
    this.targetAudience = 'All Users',
    this.ctaText,
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
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      type: json['type'] as String? ?? 'Home Carousel',
      targetAudience: json['target_audience'] as String? ?? 'All Users',
      ctaText: json['cta_text'] as String?,
      deepLink: json['deep_link'] as String?,
      externalUrl: json['external_url'] as String?,
      priority: json['priority'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      clickCount: json['click_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'type': type,
      'target_audience': targetAudience,
      'cta_text': ctaText,
      'deep_link': deepLink,
      'external_url': externalUrl,
      'priority': priority,
      'is_active': isActive,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  Banner copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? type,
    String? targetAudience,
    String? ctaText,
    String? deepLink,
    String? externalUrl,
    int? priority,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? clickCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      targetAudience: targetAudience ?? this.targetAudience,
      ctaText: ctaText ?? this.ctaText,
      deepLink: deepLink ?? this.deepLink,
      externalUrl: externalUrl ?? this.externalUrl,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      clickCount: clickCount ?? this.clickCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
