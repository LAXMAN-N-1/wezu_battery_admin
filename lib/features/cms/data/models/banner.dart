int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

DateTime? _toDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

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
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? json['image'] ?? '').toString(),
      type: (json['type'] ?? 'Home Carousel').toString(),
      targetAudience: (json['target_audience'] ?? 'All Users').toString(),
      ctaText: json['cta_text']?.toString(),
      deepLink: json['deep_link']?.toString(),
      externalUrl: json['external_url']?.toString(),
      priority: _toInt(json['priority']),
      isActive: _toBool(json['is_active'], true),
      startDate: _toDate(json['start_date']),
      endDate: _toDate(json['end_date']),
      clickCount: _toInt(json['click_count']),
      createdAt: _toDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _toDate(json['updated_at']) ?? DateTime.now(),
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
