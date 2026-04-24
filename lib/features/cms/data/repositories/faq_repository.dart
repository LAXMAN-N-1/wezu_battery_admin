import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../models/faq.dart';

final faqRepositoryProvider = Provider<FAQRepository>((ref) {
  return FAQRepository(ref.read(apiClientProvider));
});

class FAQRepository {
  final ApiClient _apiClient;

  FAQRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/cms/faqs';
  static const String _fallbackBasePath = '/api/v1/admin/faqs';

  Future<List<FAQ>> getFaqs({
    String? category,
    bool? isActive,
    String? search,
    int skip = 0,
    int limit = 100,
  }) async {
    final query = <String, dynamic>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (isActive != null) 'is_active': isActive,
      if (search != null && search.isNotEmpty) 'q': search,
      'skip': skip,
      'offset': skip,
      'limit': limit,
    };

    final response = await _getAny(<String>['$_basePath/', _basePath, '$_fallbackBasePath/', _fallbackBasePath], query);
    final rows = _extractList(response.data, keys: <String>['items', 'faqs', 'data']);

    return rows
        .whereType<Map>()
        .map((e) => FAQ.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<FAQ> createFaq(FAQ faq) async {
    final response = await _postAny(<String>['$_basePath/', _basePath, '$_fallbackBasePath/'], faq.toJson());
    return FAQ.fromJson(_asMap(response.data));
  }

  Future<FAQ> updateFaq(int id, FAQ faq) async {
    try {
      final response = await _apiClient.put('$_basePath/$id', data: faq.toJson());
      return FAQ.fromJson(_asMap(response.data));
    } on DioException {
      final response = await _apiClient.patch('$_fallbackBasePath/$id', data: faq.toJson());
      return FAQ.fromJson(_asMap(response.data));
    }
  }

  Future<void> deleteFaq(int id) async {
    try {
      await _apiClient.delete('$_basePath/$id');
    } on DioException {
      await _apiClient.delete('$_fallbackBasePath/$id');
    }
  }

  Future<dynamic> _getAny(List<String> paths, Map<String, dynamic> query) async {
    Object? lastError;
    for (final path in paths) {
      try {
        return await _apiClient.get(path, queryParameters: query);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('GET failed for FAQ endpoints');
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
    throw lastError ?? Exception('POST failed for FAQ endpoints');
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
