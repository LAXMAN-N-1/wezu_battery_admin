import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/media_asset.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.read(apiClientProvider));
});

class MediaRepository {
  final ApiClient _apiClient;

  MediaRepository([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  static const _cmsMediaPath = '/api/v1/admin/cms/media/';

  Future<List<MediaAsset>> getMediaAssets({String? category}) async {
    try {
      final response = await _apiClient.get(
        _cmsMediaPath,
        queryParameters: {if (category != null) 'category': category},
      );
      return (response.data as List)
          .map((e) => MediaAsset.fromJson(e))
          .toList();
    } on DioException {
      // Legacy fallback for older backend builds.
      final response = await _apiClient.get(
        '/api/v1/admin/media',
        queryParameters: {if (category != null) 'category': category},
      );
      return (response.data as List)
          .map((e) => MediaAsset.fromJson(e))
          .toList();
    }
  }

  Future<MediaAsset> uploadMedia(
    File file, {
    String category = 'general',
    String? altText,
  }) async {
    final String fileName = file.path.split('/').last;
    final fileSize = await file.length();
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'bin';
    final mime = _extensionToMimeType(ext);

    // Use the CMS media endpoint directly.
    // The old /api/v1/admin/media/upload route returns 405 (Method Not Allowed)
    // and should not be called.
    try {
      final response = await _apiClient.post(
        _cmsMediaPath,
        queryParameters: {
          'file_name': fileName,
          'file_type': mime,
          'file_size_bytes': fileSize,
          'url': file.path,
          'category': category,
          if (altText != null) 'alt_text': altText,
        },
      );
      return MediaAsset.fromJson(response.data);
    } on DioException {
      // Fallback: try multipart upload if the query-param approach fails.
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'category': category,
        if (altText != null) 'alt_text': altText,
      });

      final response = await _apiClient.post(
        _cmsMediaPath,
        data: formData,
      );
      return MediaAsset.fromJson(response.data);
    }
  }

  Future<void> deleteMediaAsset(int id) async {
    try {
      await _apiClient.delete('/api/v1/admin/cms/media/$id');
    } on DioException {
      await _apiClient.delete('/api/v1/admin/media/$id');
    }
  }

  String _extensionToMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
