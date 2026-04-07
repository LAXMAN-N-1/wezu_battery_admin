import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/legal_document.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.read(apiClientProvider));
});

class LegalRepository {
  final ApiClient _apiClient;

  LegalRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/cms/legal';

  Future<List<LegalDocument>> getLegalDocuments() async {
    final response = await _apiClient.get('$_basePath/');
    return (response.data as List).map((e) => LegalDocument.fromJson(e)).toList();
  }

  Future<LegalDocument> getLegalDocument(int id) async {
    final response = await _apiClient.get('$_basePath/$id');
    return LegalDocument.fromJson(response.data);
  }

  Future<LegalDocument> createLegalDocument(LegalDocument doc) async {
    final response = await _apiClient.post(
      '$_basePath/',
      data: doc.toJson(),
    );
    return LegalDocument.fromJson(response.data);
  }

  Future<LegalDocument> updateLegalDocument(int id, LegalDocument doc) async {
    final response = await _apiClient.patch(
      '$_basePath/$id',
      data: doc.toJson(),
    );
    return LegalDocument.fromJson(response.data);
  }

  Future<void> deleteLegalDocument(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
