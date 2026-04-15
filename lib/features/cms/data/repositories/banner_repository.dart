import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.read(apiClientProvider));
});

class BannerRepository {
  final ApiClient _apiClient;

  BannerRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  static const String _basePath = '/api/v1/admin/cms/banners';

  Future<List<Banner>> getBanners() async {
    final response = await _apiClient.get('$_basePath/');
    return (response.data as List).map((e) => Banner.fromJson(e)).toList();
  }

  Future<Banner> createBanner(Banner banner) async {
    final response = await _apiClient.post(
      '$_basePath/',
      data: banner.toJson(),
    );
    return Banner.fromJson(response.data);
  }

  Future<Banner> updateBanner(int id, Banner banner) async {
    final response = await _apiClient.patch(
      '$_basePath/$id',
      data: banner.toJson(),
    );
    return Banner.fromJson(response.data);
  }

  Future<void> deleteBanner(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }
}
