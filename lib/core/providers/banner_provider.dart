import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';

class BannerState {
  final List<BannerModel> banners;
  final bool isLoading;

  BannerState({
    this.banners = const [],
    this.isLoading = false,
  });

  BannerState copyWith({
    List<BannerModel>? banners,
    bool? isLoading,
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final bannerProvider = StateNotifierProvider<BannerNotifier, BannerState>((ref) {
  return BannerNotifier();
});

class BannerNotifier extends StateNotifier<BannerState> {
  BannerNotifier() : super(BannerState(isLoading: true)) {
    loadBanners();
  }

  List<BannerModel> _allBanners = [];

  Future<void> loadBanners() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Initialize Mock Data only once
      if (_allBanners.isEmpty) {
        _allBanners = [
          BannerModel(
            id: 'B1',
            title: 'Welcome Promo',
            imageUrl: 'https://via.placeholder.com/800x200',
            type: BannerType.promotional,
            isActive: true,
            createdAt: DateTime.now(),
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 7)),
          ),
          BannerModel(
            id: 'B2',
            title: 'System Maintenance',
            imageUrl: 'https://via.placeholder.com/800x200',
            type: BannerType.alert,
            isActive: true,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ];
      }

      state = state.copyWith(banners: List.from(_allBanners), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addBanner(BannerModel banner) async {
    _allBanners.add(banner);
    loadBanners();
  }

  Future<void> updateBanner(BannerModel banner) async {
    final index = _allBanners.indexWhere((b) => b.id == banner.id);
    if (index != -1) {
      _allBanners[index] = banner;
      loadBanners();
    }
  }

  Future<void> toggleStatus(String id) async {
    final index = _allBanners.indexWhere((b) => b.id == id);
    if (index != -1) {
      final banner = _allBanners[index];
      _allBanners[index] = BannerModel(
        id: banner.id,
        title: banner.title,
        imageUrl: banner.imageUrl,
        type: banner.type,
        isActive: !banner.isActive,
        createdAt: banner.createdAt,
        startDate: banner.startDate,
        endDate: banner.endDate,
      );
      loadBanners();
    }
  }

  Future<void> deleteBanner(String id) async {
    _allBanners.removeWhere((b) => b.id == id);
    loadBanners();
  }
}
