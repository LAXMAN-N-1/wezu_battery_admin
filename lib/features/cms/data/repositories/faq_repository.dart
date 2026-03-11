import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/faq.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository(ref.read(apiClientProvider));
});

class FaqRepository {
  final ApiClient _apiClient;

  FaqRepository(this._apiClient);
  
  Future<List<FAQ>> getFaqs({String? category, String? q}) async {
    final response = await _apiClient.get(
      '/api/v1/faqs/',
      queryParameters: {
        if (category != null) 'category': category,
        if (q != null) 'q': q,
      },
    );
    return (response.data as List).map((e) => FAQ.fromJson(e)).toList();
  }

  Future<FAQ> createFaq(FAQ faq) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/admin/main/cms/faqs/',
        data: faq.toJson(),
      );
      return FAQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create FAQ: $e');
    }
  }

  Future<FAQ> updateFaq(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/admin/main/cms/faqs/$id',
        data: data,
      );
      return FAQ.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update FAQ: $e');
    }
  }

  Future<void> deleteFaq(int id) async {
    try {
      await _apiClient.delete('/api/v1/admin/main/cms/faqs/$id');
    } catch (e) {
      throw Exception('Failed to delete FAQ: $e');
    }
  }
}
