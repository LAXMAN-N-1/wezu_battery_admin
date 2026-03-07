import '../../../core/api/api_client.dart';
import '../models/faq.dart';

class FaqRepository {
  final ApiClient _apiClient = ApiClient();

  // Note: List/Detail use public endpoints, Create/Update/Delete use admin endpoints
  // In this app, for simplicity in admin panel, we can use admin endpoints if they exist for all
  
  Future<List<FAQ>> getFaqs({String? category, String? q}) async {
    try {
      final response = await _apiClient.dio.get(
        '/faqs', // Using public endpoint for listing
        queryParameters: {
          if (category != null) 'category': category,
          if (q != null) 'q': q,
        },
      );
      return (response.data as List).map((e) => FAQ.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<FAQ> createFaq(FAQ faq) async {
    try {
      final response = await _apiClient.dio.post(
        '/admin/faq', // Note: backend uses /admin/faq for POST
        data: faq.toJson(),
      );
      return FAQ.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<FAQ> updateFaq(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '/admin/faq/$id', // Note: backend uses /admin/faq/{id} for PUT
        data: data,
      );
      return FAQ.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFaq(int id) async {
    try {
      await _apiClient.dio.delete('/admin/faq/$id');
    } catch (e) {
      rethrow;
    }
  }
}
