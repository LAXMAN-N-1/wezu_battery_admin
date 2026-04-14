class Blog {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String? summary;
  final String? featuredImageUrl;
  final String category;
  final int authorId;
  final String status;
  final int viewsCount;
  final List<String> tags;
  final String? metaTitle;
  final String? metaDescription;
  final String? focusKeyword;
  final int? readingTimeMinutes;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Blog({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.summary,
    this.featuredImageUrl,
    required this.category,
    required this.authorId,
    required this.status,
    required this.viewsCount,
    this.tags = const [],
    this.metaTitle,
    this.metaDescription,
    this.focusKeyword,
    this.readingTimeMinutes,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      featuredImageUrl: json['featured_image_url'] as String?,
      category: json['category'] as String,
      authorId: json['author_id'] as int,
      status: (json['status'] as String).toLowerCase(),
      viewsCount: json['views_count'] as int? ?? 0,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
      focusKeyword: json['focus_keyword'] as String?,
      readingTimeMinutes: json['reading_time_minutes'] as int?,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'summary': summary,
      'featured_image_url': featuredImageUrl,
      'category': category,
      'author_id': authorId,
      'status': status,
      'tags': tags,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'focus_keyword': focusKeyword,
      'reading_time_minutes': readingTimeMinutes,
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  Blog copyWith({
    int? id,
    String? title,
    String? slug,
    String? content,
    String? summary,
    String? featuredImageUrl,
    String? category,
    int? authorId,
    String? status,
    int? viewsCount,
    List<String>? tags,
    String? metaTitle,
    String? metaDescription,
    String? focusKeyword,
    int? readingTimeMinutes,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Blog(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      tags: tags ?? this.tags,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      focusKeyword: focusKeyword ?? this.focusKeyword,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
