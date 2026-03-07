import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/blog.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.read(apiClientProvider));
});

class BlogRepository {
  final ApiClient _apiClient;

  BlogRepository(this._apiClient);

  Future<List<Blog>> getBlogs({String? category, String? status}) async {
    try {
      final response = await _apiClient.dio.get(
        'admin/blogs',
        queryParameters: {
          if (category != null) 'category': category,
          if (status != null) 'status': status,
        },
      );
      return (response.data as List).map((e) => Blog.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Blog> getBlog(int id) async {
    try {
      final response = await _apiClient.dio.get('admin/blogs/$id');
      return Blog.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Blog> createBlog(Blog blog) async {
    try {
      final response = await _apiClient.dio.post(
        'admin/blogs',
        data: blog.toJson(),
      );
      return Blog.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Blog> updateBlog(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        'admin/blogs/$id',
        data: data,
      );
      return Blog.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBlog(int id) async {
    try {
      await _apiClient.dio.delete('admin/blogs/$id');
    } catch (e) {
      rethrow;
    }
  }
}
