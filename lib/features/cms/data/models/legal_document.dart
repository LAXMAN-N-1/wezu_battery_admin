class LegalDocument {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String version;
  final String status; // DRAFT | PUBLISHED | ARCHIVED
  final bool isActive;
  final bool forceUpdate;
  final DateTime? effectiveDate;
  final String? lastUpdatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LegalVersion>? history;

  LegalDocument({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.version,
    this.status = 'DRAFT',
    required this.isActive,
    required this.forceUpdate,
    this.effectiveDate,
    this.lastUpdatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.history,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      content: json['content'] as String,
      version: json['version'] as String? ?? '1.0',
      status: json['status'] as String? ?? 'DRAFT',
      isActive: json['is_active'] as bool? ?? true,
      forceUpdate: json['force_update'] as bool? ?? false,
      effectiveDate: json['effective_date'] != null ? DateTime.parse(json['effective_date'] as String) : null,
      lastUpdatedBy: json['last_updated_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      history: (json['history'] as List?)?.map((e) => LegalVersion.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'version': version,
      'status': status,
      'is_active': isActive,
      'force_update': forceUpdate,
      'effective_date': effectiveDate?.toIso8601String(),
    };
  }
}

class LegalVersion {
  final String version;
  final String content;
  final String publishedBy;
  final DateTime publishedAt;

  LegalVersion({
    required this.version,
    required this.content,
    required this.publishedBy,
    required this.publishedAt,
  });

  factory LegalVersion.fromJson(Map<String, dynamic> json) {
    return LegalVersion(
      version: json['version'] as String,
      content: json['content'] as String,
      publishedBy: json['published_by'] as String? ?? 'Admin',
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }
}
