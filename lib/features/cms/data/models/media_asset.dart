class MediaAsset {
  final int id;
  final String fileName;
  final String fileType;
  final int fileSizeByes;
  final String url;
  final String? altText;
  final String category;
  final int uploadedById;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaAsset({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSizeByes,
    required this.url,
    this.altText,
    required this.category,
    required this.uploadedById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSizeByes: json['file_size_bytes'] ?? 0,
      url: json['url'],
      altText: json['alt_text'],
      category: json['category'] ?? 'general',
      uploadedById: json['uploaded_by_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isImage => fileType.startsWith('image/');
  bool get isPdf => fileType == 'application/pdf';
}
