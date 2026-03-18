import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.read(apiClientProvider));
});

class BannerRepository {
  final ApiClient _apiClient;

  BannerRepository(this._apiClient);

  Future<List<Banner>> getBanners() async {
    try {
      final response = await _apiClient.dio.get('admin/banners');
      return (response.data as List).map((e) => Banner.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Banner> createBanner(Banner banner) async {
    try {
      final response = await _apiClient.dio.post(
        'admin/banners',
        data: banner.toJson(),
      );
      return Banner.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Banner> updateBanner(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        'admin/banners/$id',
        data: data,
      );
      return Banner.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      await _apiClient.dio.delete('admin/banners/$id');
    } catch (e) {
      rethrow;
    }
  }
}
