import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/banner_model.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository();
});

class BannerRepository {
  final List<BannerModel> _mockBanners = [];

  BannerRepository() {
    _generateMockBanners();
  }

  void _generateMockBanners() {
    _mockBanners.addAll([
      BannerModel(
        id: 'BNR-001',
        title: 'New User Promo',
        imageUrl: 'https://placehold.co/800x400/png?text=New+User+Offer',
        type: BannerType.promotional,
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        targetScreen: '/promotions',
        priority: 10,
      ),
      BannerModel(
        id: 'BNR-002',
        title: 'Battery Safety Tips',
        imageUrl: 'https://placehold.co/800x400/png?text=Safety+Tips',
        type: BannerType.informational,
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 90)),
        targetScreen: '/help',
        priority: 5,
      ),
      BannerModel(
        id: 'BNR-003',
        title: 'Holiday Special',
        imageUrl: 'https://placehold.co/800x400/png?text=Holiday+Special',
        type: BannerType.promotional,
        isActive: false,
        startDate: DateTime.now().add(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        targetScreen: '/offers',
        priority: 1,
      ),
    ]);
  }

  Future<List<BannerModel>> fetchBanners() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_mockBanners);
  }

  Future<void> addBanner(BannerModel banner) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _mockBanners.add(banner);
  }

  Future<void> updateBanner(BannerModel banner) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _mockBanners.indexWhere((b) => b.id == banner.id);
    if (index != -1) {
      _mockBanners[index] = banner;
    }
  }

  Future<void> deleteBanner(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _mockBanners.removeWhere((b) => b.id == id);
  }

  Future<void> toggleStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockBanners.indexWhere((b) => b.id == id);
    if (index != -1) {
      final banner = _mockBanners[index];
      _mockBanners[index] = banner.copyWith(isActive: !banner.isActive);
    }
  }
}
