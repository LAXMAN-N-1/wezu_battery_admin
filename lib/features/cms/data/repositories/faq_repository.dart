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

  Future<List<FAQ>> getFaqs({String? category, bool? isActive, int skip = 0, int limit = 100}) async {
    final response = await _apiClient.get(
      '$_basePath/',
      queryParameters: {
        if (category != null) 'category': category,
        if (isActive != null) 'is_active': isActive,
        'skip': skip,
        'limit': limit,
      },
    );
    return (response.data as List).map((e) => FAQ.fromJson(e)).toList();
  }

  Future<FAQ> createFaq(FAQ faq) async {
    final response = await _apiClient.post(
      '$_basePath/',
      data: faq.toJson(),
    );
    return FAQ.fromJson(response.data);
  }

  Future<FAQ> updateFaq(int id, FAQ faq) async {
    final response = await _apiClient.put(
      '$_basePath/$id',
      data: faq.toJson(),
    );
    return FAQ.fromJson(response.data);
  }

  Future<void> deleteFaq(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
