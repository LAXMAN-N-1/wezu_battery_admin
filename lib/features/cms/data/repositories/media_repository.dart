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

  MediaRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  Future<List<MediaAsset>> getMediaAssets({String? category}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/media',
      queryParameters: {
        if (category != null) 'category': category,
      },
    );
    return (response.data as List).map((e) => MediaAsset.fromJson(e)).toList();
  }

  Future<MediaAsset> uploadMedia(File file, {String category = 'general', String? altText}) async {
    final String fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'category': category,
      if (altText != null) 'alt_text': altText,
    });

    final response = await _apiClient.post(
      '/api/v1/admin/media/upload',
      data: formData,
    );
    return MediaAsset.fromJson(response.data);
  }

  Future<void> deleteMediaAsset(int id) async {
    await _apiClient.delete('/api/v1/admin/media/$id');
  }
}
