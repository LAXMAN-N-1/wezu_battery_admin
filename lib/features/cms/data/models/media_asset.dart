class MediaAsset {
  final int id;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String url;
  final String? altText;
  final String category;
  final String? folderPath; // Virtual path: "banners/summer-2026"
  final String? dimensions; // e.g. 1920x1080
  final int uploadedById;
  final String? uploadedByName;
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
    this.folderPath,
    this.dimensions,
    required this.uploadedById,
    this.uploadedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      url: json['url'] as String,
      altText: json['alt_text'] as String?,
      category: json['category'] as String? ?? 'general',
      folderPath: json['folder_path'] as String?,
      dimensions: json['dimensions'] as String?,
      uploadedById: json['uploaded_by_id'] as int,
      uploadedByName: json['uploaded_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isImage => fileType.startsWith('image/');
  bool get isVideo => fileType.startsWith('video/');
  bool get isPdf => fileType == 'application/pdf';

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'alt_text': altText,
      'category': category,
      'folder_path': folderPath,
    };
  }
}

class Folder {
  final String name;
  final String path;
  final List<Folder> subFolders;

  Folder({
    required this.name,
    required this.path,
    this.subFolders = const [],
  });
}
