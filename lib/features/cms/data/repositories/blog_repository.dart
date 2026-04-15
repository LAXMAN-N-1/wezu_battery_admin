import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/blog.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.read(apiClientProvider));
});

class BlogRepository {
  final ApiClient _apiClient;

  BlogRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/cms/blogs';

  Future<List<Blog>> getBlogs({String? category, String? status, int skip = 0, int limit = 100}) async {
    final response = await _apiClient.get(
      '$_basePath/',
      queryParameters: {
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        'skip': skip,
        'limit': limit,
      },
    );
    return (response.data as List).map((e) => Blog.fromJson(e)).toList();
  }

  Future<Blog> getBlog(int id) async {
    final response = await _apiClient.get('$_basePath/$id');
    return Blog.fromJson(response.data);
  }

  Future<Blog> createBlog(Blog blog) async {
    final response = await _apiClient.post(
      '$_basePath/',
      data: blog.toJson(),
    );
    return Blog.fromJson(response.data);
  }

  Future<Blog> updateBlog(int id, Blog blog) async {
    final response = await _apiClient.put(
      '$_basePath/$id',
      data: blog.toJson(),
    );
    return Blog.fromJson(response.data);
  }

  Future<void> deleteBlog(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
