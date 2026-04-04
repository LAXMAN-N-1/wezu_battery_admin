import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.read(apiClientProvider));
});

class BannerRepository {
  final ApiClient _apiClient;

  BannerRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  Future<List<Banner>> getBanners() async {
    final response = await _apiClient.get('/api/v1/admin/banners');
    return (response.data as List).map((e) => Banner.fromJson(e)).toList();
  }

  Future<Banner> createBanner(Banner banner) async {
    final response = await _apiClient.post(
      '/api/v1/admin/banners',
      data: banner.toJson(),
    );
    return Banner.fromJson(response.data);
  }

  Future<Banner> updateBanner(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      '/api/v1/admin/banners/$id',
      data: data,
    );
    return Banner.fromJson(response.data);
  }

  Future<void> deleteBanner(int id) async {
    await _apiClient.delete('/api/v1/admin/banners/$id');
  }
}
