import 'package:dio/dio.dart';
import 'package:frontend_admin/core/api/api_client.dart';
import '../models/blog.dart';

class BlogRepository {
  final ApiClient _apiClient;

  BlogRepository(this._apiClient);

  static const String _basePath = '/api/v1/admin/main/cms/blogs';

  Future<List<Blog>> getBlogs({String? category, String? status}) async {
    try {
      final response = await _apiClient.get(
        '$_basePath/',
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
      final response = await _apiClient.get('$_basePath/$id');
      return Blog.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Blog> createBlog(Blog blog) async {
    try {
      final response = await _apiClient.post(
        '$_basePath/',
        data: blog.toJson(),
      );
      return Blog.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Blog> updateBlog(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '$_basePath/$id',
        data: data,
      );
      return Blog.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBlog(int id) async {
    try {
      await _apiClient.delete('$_basePath/$id');
    } catch (e) {
      rethrow;
    }
  }
}
