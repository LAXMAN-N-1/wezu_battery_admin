import '../../../core/api/api_client.dart';
import '../models/legal_document.dart';

class LegalRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<LegalDocument>> getLegalDocuments() async {
    try {
      final response = await _apiClient.dio.get('/admin/legal');
      return (response.data as List).map((e) => LegalDocument.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LegalDocument> getLegalDocument(int id) async {
    try {
      final response = await _apiClient.dio.get('/admin/legal/$id');
      return LegalDocument.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<LegalDocument> createLegalDocument(LegalDocument doc) async {
    try {
      final response = await _apiClient.dio.post(
        '/admin/legal',
        data: doc.toJson(),
      );
      return LegalDocument.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<LegalDocument> updateLegalDocument(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        '/admin/legal/$id',
        data: data,
      );
      return LegalDocument.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLegalDocument(int id) async {
    try {
      await _apiClient.dio.delete('/admin/legal/$id');
    } catch (e) {
      rethrow;
    }
  }
}
