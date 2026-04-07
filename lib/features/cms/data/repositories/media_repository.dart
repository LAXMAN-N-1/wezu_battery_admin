import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/media_asset.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.read(apiClientProvider));
});

class MediaRepository {
  final ApiClient _apiClient;

  MediaRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/cms/media';

  Future<List<MediaAsset>> getMediaAssets({String? category}) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: {if (category != null) 'category': category},
    );
    return (response.data as List).map((e) => MediaAsset.fromJson(e)).toList();
  }

  Future<MediaAsset> createMediaAsset({
    required String fileName,
    required String fileType,
    required int fileSizeBytes,
    required String url,
    String? altText,
    String category = 'general',
  }) async {
    final response = await _apiClient.post(
      '$_basePath/',
      data: {
        'file_name': fileName,
        'file_type': fileType,
        'file_size_bytes': fileSizeBytes,
        'url': url,
        if (altText != null) 'alt_text': altText,
        'category': category,
      },
    );
    return MediaAsset.fromJson(response.data);
  }

  Future<MediaAsset> updateMediaAsset(int id, {String? altText, String? category}) async {
    final response = await _apiClient.patch(
      '$_basePath/$id',
      data: {
        if (altText != null) 'alt_text': altText,
        if (category != null) 'category': category,
      },
    );
    return MediaAsset.fromJson(response.data);
  }

  Future<void> deleteMediaAsset(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
