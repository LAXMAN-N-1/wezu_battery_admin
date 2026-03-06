import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/media_asset.dart';

class MediaRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<MediaAsset>> getMediaAssets({String? category}) async {
    try {
      final response = await _apiClient.dio.get(
        '/admin/media',
        queryParameters: {
          if (category != null) 'category': category,
        },
      );
      return (response.data as List).map((e) => MediaAsset.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<MediaAsset> uploadMedia(File file, {String category = 'general', String? altText}) async {
    try {
      final String fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'category': category,
        if (altText != null) 'alt_text': altText,
      });

      final response = await _apiClient.dio.post(
        '/admin/media/upload',
        data: formData,
      );
      return MediaAsset.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMediaAsset(int id) async {
    try {
      await _apiClient.dio.delete('/admin/media/$id');
    } catch (e) {
      rethrow;
    }
  }
}
