import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/legal_document.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.read(apiClientProvider));
});

class LegalRepository {
  final ApiClient _apiClient;

  LegalRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  Future<List<LegalDocument>> getLegalDocuments() async {
    final response = await _apiClient.get('/api/v1/admin/legal');
    return (response.data as List).map((e) => LegalDocument.fromJson(e)).toList();
  }

  Future<LegalDocument> getLegalDocument(int id) async {
    final response = await _apiClient.get('/api/v1/admin/legal/$id');
    return LegalDocument.fromJson(response.data);
  }

  Future<LegalDocument> createLegalDocument(LegalDocument doc) async {
    final response = await _apiClient.post(
      '/api/v1/admin/legal',
      data: doc.toJson(),
    );
    return LegalDocument.fromJson(response.data);
  }

  Future<LegalDocument> updateLegalDocument(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      '/api/v1/admin/legal/$id',
      data: data,
    );
    return LegalDocument.fromJson(response.data);
  }

  Future<void> deleteLegalDocument(int id) async {
    await _apiClient.delete('/api/v1/admin/legal/$id');
  }
}
