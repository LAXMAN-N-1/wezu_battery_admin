import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/blog.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.read(apiClientProvider));
});

class BlogRepository {
  final ApiClient _apiClient;

  BlogRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/blogs';

  Future<List<Blog>> getBlogs({String? category, String? status}) async {
    final response = await _apiClient.get(
      _basePath,
      queryParameters: {
        if (category != null) 'category': category,
        if (status != null) 'status': status,
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
      _basePath,
      data: blog.toJson(),
    );
    return Blog.fromJson(response.data);
  }

  Future<Blog> updateBlog(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      '$_basePath/$id',
      data: data,
    );
    return Blog.fromJson(response.data);
  }

  Future<void> deleteBlog(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
