import 'package:dio/dio.dart';
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
  static const String _fallbackBasePath = '/api/v1/admin/legal';

  Future<List<LegalDocument>> getLegalDocuments() async {
    final response = await _getAny(<String>[
      '$_basePath/',
      _basePath,
      '$_fallbackBasePath/',
      _fallbackBasePath,
    ]);

    final rows = _extractList(response.data, keys: <String>['items', 'documents', 'data']);
    return rows
        .whereType<Map>()
        .map((e) => LegalDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<LegalDocument> getLegalDocument(int id) async {
    try {
      final response = await _apiClient.get('$_basePath/$id');
      return LegalDocument.fromJson(_asMap(response.data));
    } on DioException {
      final response = await _apiClient.get('$_fallbackBasePath/$id');
      return LegalDocument.fromJson(_asMap(response.data));
    }
  }

  Future<LegalDocument> createLegalDocument(LegalDocument doc) async {
    final response = await _postAny(<String>['$_basePath/', _basePath, '$_fallbackBasePath/'], doc.toJson());
    return LegalDocument.fromJson(_asMap(response.data));
  }

  Future<LegalDocument> updateLegalDocument(int id, LegalDocument doc) async {
    try {
      final response = await _apiClient.patch('$_basePath/$id', data: doc.toJson());
      return LegalDocument.fromJson(_asMap(response.data));
    } on DioException {
      final response = await _apiClient.put('$_fallbackBasePath/$id', data: doc.toJson());
      return LegalDocument.fromJson(_asMap(response.data));
    }
  }

  Future<void> deleteLegalDocument(int id) async {
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
    throw lastError ?? Exception('GET failed for legal endpoints');
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
    throw lastError ?? Exception('POST failed for legal endpoints');
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
