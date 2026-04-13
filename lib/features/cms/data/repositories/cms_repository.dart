import '../../../../core/api/api_client.dart';

class CmsRepository {
  final ApiClient _apiClient;
  CmsRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/cms';

  // ─────────────────────────────────────────
  // BLOGS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBlogs({
    String? category,
    String? status,
    int skip = 0,
    int limit = 100,
  }) async {
    final r = await _apiClient.get(
      '$_base/blogs/',
      queryParameters: {
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        'skip': skip,
        'limit': limit,
      },
    );
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBlog(int id) async {
    final r = await _apiClient.get('$_base/blogs/$id');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBlog(Map<String, dynamic> data) async {
    final r = await _apiClient.post('$_base/blogs/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBlog(int id, Map<String, dynamic> data) async {
    final r = await _apiClient.put('$_base/blogs/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteBlog(int id) async => await _apiClient.delete('$_base/blogs/$id');

  // ─────────────────────────────────────────
  // FAQS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFaqs({
    String? category,
    bool? isActive,
    int skip = 0,
    int limit = 100,
  }) async {
    final r = await _apiClient.get(
      '$_base/faqs/',
      queryParameters: {
        if (category != null) 'category': category,
        if (isActive != null) 'is_active': isActive,
        'skip': skip,
        'limit': limit,
      },
    );
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createFaq(Map<String, dynamic> data) async {
    final r = await _apiClient.post('$_base/faqs/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateFaq(int id, Map<String, dynamic> data) async {
    final r = await _apiClient.put('$_base/faqs/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> updateFaqStatus(int id, bool isActive) async {
    await _apiClient.patch('$_base/faqs/$id/status', data: {'is_active': isActive});
  }

  Future<void> updateFaqOrder(List<int> faqIds) async {
    await _apiClient.put('$_base/faqs/reorder', data: {'faq_ids': faqIds});
  }

  Future<void> deleteFaq(int id) async => await _apiClient.delete('$_base/faqs/$id');

  // ─────────────────────────────────────────
  // BANNERS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBanners() async {
    final r = await _apiClient.get('$_base/banners/');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> data) async {
    final r = await _apiClient.post('$_base/banners/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBanner(int id, Map<String, dynamic> data) async {
    final r = await _apiClient.patch('$_base/banners/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteBanner(int id) async => await _apiClient.delete('$_base/banners/$id');

  // ─────────────────────────────────────────
  // LEGAL DOCUMENTS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLegalDocs() async {
    final r = await _apiClient.get('$_base/legal/');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createLegalDoc(Map<String, dynamic> data) async {
    final r = await _apiClient.post('$_base/legal/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLegalDoc(int id, Map<String, dynamic> data) async {
    final r = await _apiClient.patch('$_base/legal/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteLegalDoc(int id) async => await _apiClient.delete('$_base/legal/$id');

  // ─────────────────────────────────────────
  // MEDIA ASSETS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMediaAssets({String? category}) async {
    final r = await _apiClient.get(
      '$_base/media/',
      queryParameters: {if (category != null) 'category': category},
    );
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createMediaAsset({
    required String fileName,
    required String fileType,
    required int fileSizeBytes,
    required String url,
    String? altText,
    String category = 'general',
    String? folderPath,
  }) async {
    final r = await _apiClient.post(
      '$_base/media/',
      queryParameters: {
        'file_name': fileName,
        'file_type': fileType,
        'file_size_bytes': fileSizeBytes,
        'url': url,
        if (altText != null) 'alt_text': altText,
        'category': category,
        if (folderPath != null) 'folder_path': folderPath,
      },
    );
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMediaAsset(int id, Map<String, dynamic> data) async {
    final r = await _apiClient.patch('$_base/media/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteMediaAsset(int id) async => await _apiClient.delete('$_base/media/$id');
}
