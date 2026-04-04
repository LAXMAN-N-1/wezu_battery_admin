import '../../../../core/api/api_client.dart';

class CmsRepository {
  final ApiClient _apiClient;
  CmsRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/cms';

  // Blogs
  Future<List<Map<String, dynamic>>> getBlogs({String? category, String? status}) async {
    final r = await _apiClient.get('$_base/blogs/', queryParameters: {if (category != null) 'category': category, if (status != null) 'status': status});
    return (r.data as List).cast<Map<String, dynamic>>();
  }
  Future<void> createBlog(Map<String, dynamic> data) async => await _apiClient.post('$_base/blogs/', data: data);
  Future<void> updateBlog(int id, Map<String, dynamic> data) async => await _apiClient.put('$_base/blogs/$id', data: data);
  Future<void> deleteBlog(int id) async => await _apiClient.delete('$_base/blogs/$id');

  // FAQs
  Future<List<Map<String, dynamic>>> getFaqs({String? category}) async {
    final r = await _apiClient.get('$_base/faqs/', queryParameters: {if (category != null) 'category': category});
    return (r.data as List).cast<Map<String, dynamic>>();
  }
  Future<void> createFaq(Map<String, dynamic> data) async => await _apiClient.post('$_base/faqs/', data: data);
  Future<void> updateFaq(int id, Map<String, dynamic> data) async => await _apiClient.put('$_base/faqs/$id', data: data);
  Future<void> deleteFaq(int id) async => await _apiClient.delete('$_base/faqs/$id');

  // Banners
  Future<List<Map<String, dynamic>>> getBanners() async {
    final r = await _apiClient.get('$_base/banners/');
    return (r.data as List).cast<Map<String, dynamic>>();
  }
  Future<void> createBanner(Map<String, dynamic> data) async => await _apiClient.post('$_base/banners/', data: data);
  Future<void> updateBanner(int id, Map<String, dynamic> data) async => await _apiClient.patch('$_base/banners/$id', data: data);
  Future<void> deleteBanner(int id) async => await _apiClient.delete('$_base/banners/$id');

  // Legal
  Future<List<Map<String, dynamic>>> getLegalDocs() async {
    final r = await _apiClient.get('$_base/legal/');
    return (r.data as List).cast<Map<String, dynamic>>();
  }
  Future<void> createLegalDoc(Map<String, dynamic> data) async => await _apiClient.post('$_base/legal/', data: data);
  Future<void> updateLegalDoc(int id, Map<String, dynamic> data) async => await _apiClient.patch('$_base/legal/$id', data: data);
  Future<void> deleteLegalDoc(int id) async => await _apiClient.delete('$_base/legal/$id');

  // Media
  Future<List<Map<String, dynamic>>> getMediaAssets({String? category}) async {
    final r = await _apiClient.get('$_base/media/', queryParameters: {if (category != null) 'category': category});
    return (r.data as List).cast<Map<String, dynamic>>();
  }
  Future<void> createMediaAsset(String fileName, String fileType, int size, String url, {String category = 'general', String? altText}) async {
    await _apiClient.post('$_base/media/', queryParameters: {
      'file_name': fileName, 'file_type': fileType, 'file_size_bytes': size, 'url': url,
      if (altText != null) 'alt_text': altText, 'category': category,
    });
  }
  Future<void> updateMediaAsset(int id, Map<String, dynamic> data) async => await _apiClient.patch('$_base/media/$id', data: data);
  Future<void> deleteMediaAsset(int id) async => await _apiClient.delete('$_base/media/$id');
}
