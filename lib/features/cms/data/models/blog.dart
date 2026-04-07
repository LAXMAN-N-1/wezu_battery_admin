import 'dart:convert';

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
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'],
      featuredImageUrl: json['featured_image_url'],
      category: json['category'] ?? 'general',
      authorId: json['author_id'] ?? 0,
      status: json['status'] ?? 'draft',
      viewsCount: json['views_count'] ?? 0,
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
      'summary': summary ?? '',
      'featured_image_url': featuredImageUrl,
      'category': category,
      'status': status,
      'author_id': authorId,
      'views_count': viewsCount,
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  Blog copyWith({
    String? title,
    String? slug,
    String? content,
    String? summary,
    String? featuredImageUrl,
    String? category,
    String? status,
    DateTime? publishedAt,
  }) {
    return Blog(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      category: category ?? this.category,
      authorId: authorId,
      status: status ?? this.status,
      viewsCount: viewsCount,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
