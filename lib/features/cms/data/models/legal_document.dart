class LegalDocument {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String version;
  final bool isActive;
  final bool forceUpdate;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  LegalDocument({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.version,
    required this.isActive,
    required this.forceUpdate,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      version: json['version'] ?? '1.0.0',
      isActive: json['is_active'] ?? true,
      forceUpdate: json['force_update'] ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'version': version,
      'is_active': isActive,
      'force_update': forceUpdate,
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  LegalDocument copyWith({
    String? title,
    String? slug,
    String? content,
    String? version,
    bool? isActive,
    bool? forceUpdate,
    DateTime? publishedAt,
  }) {
    return LegalDocument(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
