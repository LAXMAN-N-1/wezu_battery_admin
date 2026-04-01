import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/faq.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository(ref.read(apiClientProvider));
});

class FaqRepository {
  final ApiClient _apiClient;

  FaqRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  Future<List<FAQ>> getFaqs({String? category, String? q}) async {
    final response = await _apiClient.get(
      '/api/v1/faqs',
      queryParameters: {
        if (category != null) 'category': category,
        if (q != null) 'q': q,
      },
    );
    return (response.data as List).map((e) => FAQ.fromJson(e)).toList();
  }

  Future<FAQ> createFaq(FAQ faq) async {
    final response = await _apiClient.post(
      '/api/v1/admin/cms/faqs/',
      data: faq.toJson(),
    );
    return FAQ.fromJson(response.data);
  }

  Future<FAQ> updateFaq(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '/api/v1/admin/cms/faqs/$id',
      data: data,
    );
    return FAQ.fromJson(response.data);
  }

  Future<void> deleteFaq(int id) async {
    await _apiClient.delete('/api/v1/admin/cms/faqs/$id');
  }
}
