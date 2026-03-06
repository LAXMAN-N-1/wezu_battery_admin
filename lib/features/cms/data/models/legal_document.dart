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
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      version: json['version'] ?? '1.0.0',
      isActive: json['is_active'] ?? true,
      forceUpdate: json['force_update'] ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
    };
  }
}
