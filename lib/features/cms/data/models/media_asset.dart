int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _toDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

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
      id: _toInt(json['id']),
      fileName: (json['file_name'] ?? json['name'] ?? '').toString(),
      fileType: (json['file_type'] ?? json['mime_type'] ?? '').toString(),
      fileSizeBytes: _toInt(json['file_size_bytes'] ?? json['size']),
      url: (json['url'] ?? '').toString(),
      altText: json['alt_text']?.toString(),
      category: (json['category'] ?? 'general').toString(),
      folderPath: json['folder_path']?.toString(),
      dimensions: json['dimensions']?.toString(),
      uploadedById: _toInt(json['uploaded_by_id']),
      uploadedByName: json['uploaded_by_name']?.toString(),
      createdAt: _toDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _toDate(json['updated_at']) ?? DateTime.now(),
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
