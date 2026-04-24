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
    final historyRaw = json['history'];
    final history = historyRaw is List
        ? historyRaw
              .whereType<Map>()
              .map((e) => LegalVersion.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : null;

    return LegalDocument(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      version: (json['version'] ?? '1.0').toString(),
      status: (json['status'] ?? 'DRAFT').toString(),
      isActive: _toBool(json['is_active'], true),
      forceUpdate: _toBool(json['force_update']),
      effectiveDate: _toDate(json['effective_date']),
      lastUpdatedBy: json['last_updated_by']?.toString(),
      createdAt: _toDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _toDate(json['updated_at']) ?? DateTime.now(),
      history: history,
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
      version: (json['version'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      publishedBy: (json['published_by'] ?? 'Admin').toString(),
      publishedAt: _toDate(json['published_at']) ?? DateTime.now(),
    );
  }
}
