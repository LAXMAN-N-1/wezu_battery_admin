class MediaAsset {
  final int id;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
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
    required this.fileSizeBytes,
    required this.url,
    this.altText,
    required this.category,
    required this.uploadedById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] ?? 0,
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      url: json['url'] ?? '',
      altText: json['alt_text'],
      category: json['category'] ?? 'general',
      uploadedById: json['uploaded_by_id'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'url': url,
      'alt_text': altText,
      'category': category,
    };
  }

  MediaAsset copyWith({
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    String? url,
    String? altText,
    String? category,
  }) {
    return MediaAsset(
      id: id,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      url: url ?? this.url,
      altText: altText ?? this.altText,
      category: category ?? this.category,
      uploadedById: uploadedById,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isImage => fileType.startsWith('image/');
  bool get isPdf => fileType == 'application/pdf';
}
