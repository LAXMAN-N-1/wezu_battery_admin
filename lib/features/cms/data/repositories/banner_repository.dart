import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.read(apiClientProvider));
});

class BannerRepository {
  final ApiClient _apiClient;

  BannerRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/cms/banners';
  static const String _fallbackBasePath = '/api/v1/admin/banners';

  Future<List<Banner>> getBanners() async {
    final response = await _getAny(<String>[
      '$_basePath/',
      _basePath,
      '$_fallbackBasePath/',
      _fallbackBasePath,
    ]);

    final rows = _extractList(response.data, keys: <String>['items', 'banners', 'data']);
    return rows
        .whereType<Map>()
        .map((e) => Banner.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Banner> createBanner(Banner banner) async {
    final response = await _postAny(<String>['$_basePath/', _basePath, '$_fallbackBasePath/'], banner.toJson());
    return Banner.fromJson(_asMap(response.data));
  }

  Future<Banner> updateBanner(int id, Banner banner) async {
    try {
      final response = await _apiClient.patch('$_basePath/$id', data: banner.toJson());
      return Banner.fromJson(_asMap(response.data));
    } on DioException {
      final response = await _apiClient.put('$_fallbackBasePath/$id', data: banner.toJson());
      return Banner.fromJson(_asMap(response.data));
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      await _apiClient.delete('$_basePath/$id');
    } on DioException {
      await _apiClient.delete('$_fallbackBasePath/$id');
    }
  }

  Future<dynamic> _getAny(List<String> paths) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.get(path);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for banner endpoints');
  }

  Future<dynamic> _postAny(List<String> paths, Map<String, dynamic> data) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.post(path, data: data);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('POST failed for banner endpoints');
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
}
