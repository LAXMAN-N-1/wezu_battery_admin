import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/media_asset.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.read(apiClientProvider));
});

class MediaRepository {
  final ApiClient _apiClient;

  MediaRepository([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  static const _cmsMediaPath = '/api/v1/admin/cms/media';
  static const _fallbackMediaPath = '/api/v1/admin/media';

  Future<List<MediaAsset>> getMediaAssets({String? category}) async {
    final query = <String, dynamic>{if (category != null) 'category': category};

    final response = await _getAny(
      <String>['$_cmsMediaPath/', _cmsMediaPath, _fallbackMediaPath],
      query,
    );

    final rows = _extractList(response.data, keys: <String>['items', 'assets', 'media', 'data']);
    return rows
        .whereType<Map>()
        .map((e) => MediaAsset.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MediaAsset> uploadMedia(
    List<int> bytes,
    String fileName, {
    String category = 'general',
    String? altText,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'category': category,
      if (altText != null && altText.isNotEmpty) 'alt_text': altText,
    });

    try {
      final response = await _postAny(
        <String>[
          '/api/v1/admin/media/upload',
          '$_cmsMediaPath/upload',
          '$_fallbackMediaPath/upload',
        ],
        data: formData,
      );
      return MediaAsset.fromJson(_asMap(response.data));
    } on DioException {
      // Legacy fallback: create metadata row with public URL or synthetic local URL.
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'bin';
      final mime = _extensionToMimeType(ext);

      final response = await _postAny(
        <String>['$_cmsMediaPath/', _cmsMediaPath, _fallbackMediaPath],
        queryParameters: <String, dynamic>{
          'file_name': fileName,
          'file_type': mime,
          'file_size_bytes': bytes.length,
          'url': fileName,
          'category': category,
          if (altText != null && altText.isNotEmpty) 'alt_text': altText,
        },
      );
      return MediaAsset.fromJson(_asMap(response.data));
    }
  }

  Future<MediaAsset> createMediaFromUrl({
    required String url,
    required String fileName,
    String category = 'general',
    String? altText,
  }) async {
    final response = await _postAny(
      <String>['$_cmsMediaPath/', _cmsMediaPath, _fallbackMediaPath],
      queryParameters: <String, dynamic>{
        'file_name': fileName,
        'file_type': _guessMimeTypeFromUrl(url),
        'file_size_bytes': 0,
        'url': url,
        'category': category,
        if (altText != null && altText.isNotEmpty) 'alt_text': altText,
      },
    );

    return MediaAsset.fromJson(_asMap(response.data));
  }

  Future<void> deleteMediaAsset(int id) async {
    try {
      await _apiClient.delete('/api/v1/admin/cms/media/$id');
    } on DioException {
      await _apiClient.delete('/api/v1/admin/media/$id');
    }
  }

  Future<dynamic> _getAny(List<String> paths, Map<String, dynamic>? query) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.get(path, queryParameters: query);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for media endpoints');
  }

  Future<dynamic> _postAny(
    List<String> paths, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.post(
          path,
          data: data,
          queryParameters: queryParameters,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('POST failed for media endpoints');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic value, {List<String> keys = const []}) {
    if (value is List) return value;
    final map = _asMap(value);
    for (final key in keys) {
      final row = map[key];
      if (row is List) return row;
    }
    return const <dynamic>[];
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

  String _guessMimeTypeFromUrl(String url) {
    final lowered = url.toLowerCase();
    if (lowered.endsWith('.png')) return 'image/png';
    if (lowered.endsWith('.jpg') || lowered.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowered.endsWith('.webp')) return 'image/webp';
    if (lowered.endsWith('.gif')) return 'image/gif';
    if (lowered.endsWith('.svg')) return 'image/svg+xml';
    if (lowered.endsWith('.pdf')) return 'application/pdf';
    if (lowered.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
