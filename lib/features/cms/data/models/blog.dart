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
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      summary: json['summary'],
      featuredImageUrl: json['featured_image_url'],
      category: json['category'],
      authorId: json['author_id'],
      status: json['status'],
      viewsCount: json['views_count'] ?? 0,
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
      'summary': summary,
      'featured_image_url': featuredImageUrl,
      'category': category,
      'status': status,
    };
  }
}
