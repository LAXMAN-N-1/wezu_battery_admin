import 'package:flutter_riverpod/flutter_riverpod.dart';
import './models/blog.dart';
import './models/faq.dart';
import './models/banner.dart';
import './models/legal_document.dart';
import './models/media_asset.dart';
import 'repositories/blog_repository.dart';
import 'repositories/faq_repository.dart';
import 'repositories/banner_repository.dart';
import 'repositories/legal_repository.dart';
import 'repositories/media_repository.dart';

export 'repositories/blog_repository.dart';
export 'repositories/faq_repository.dart';
export 'repositories/banner_repository.dart';
export 'repositories/legal_repository.dart';
export 'repositories/media_repository.dart';

// --- Blog Providers ---

final blogListProvider = AsyncNotifierProvider<BlogListNotifier, List<Blog>>(BlogListNotifier.new);

class BlogListNotifier extends AsyncNotifier<List<Blog>> {
  @override
  Future<List<Blog>> build() async {
    return ref.watch(blogRepositoryProvider).getBlogs();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(blogRepositoryProvider).getBlogs());
  }

  Future<void> deleteBlog(int id) async {
    await ref.read(blogRepositoryProvider).deleteBlog(id);
    await refresh();
  }
}

// --- FAQ Providers ---

final faqListProvider = AsyncNotifierProvider<FAQListNotifier, List<FAQ>>(FAQListNotifier.new);

class FAQListNotifier extends AsyncNotifier<List<FAQ>> {
  @override
  Future<List<FAQ>> build() async {
    return ref.watch(faqRepositoryProvider).getFaqs();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(faqRepositoryProvider).getFaqs());
  }

  Future<void> deleteFaq(int id) async {
    await ref.read(faqRepositoryProvider).deleteFaq(id);
    await refresh();
  }
}

// --- Banner Providers ---

final bannerListProvider = AsyncNotifierProvider<BannerListNotifier, List<Banner>>(BannerListNotifier.new);

class BannerListNotifier extends AsyncNotifier<List<Banner>> {
  @override
  Future<List<Banner>> build() async {
    return ref.watch(bannerRepositoryProvider).getBanners();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(bannerRepositoryProvider).getBanners());
  }

  Future<void> deleteBanner(int id) async {
    await ref.read(bannerRepositoryProvider).deleteBanner(id);
    await refresh();
  }
}

// --- Legal Providers ---

final legalListProvider = AsyncNotifierProvider<LegalListNotifier, List<LegalDocument>>(LegalListNotifier.new);

class LegalListNotifier extends AsyncNotifier<List<LegalDocument>> {
  @override
  Future<List<LegalDocument>> build() async {
    return ref.watch(legalRepositoryProvider).getLegalDocuments();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(legalRepositoryProvider).getLegalDocuments());
  }

  Future<void> deleteLegalDoc(int id) async {
    await ref.read(legalRepositoryProvider).deleteLegalDocument(id);
    await refresh();
  }
}

// --- Media Providers ---

final mediaListProvider = AsyncNotifierProvider<MediaListNotifier, List<MediaAsset>>(MediaListNotifier.new);

class MediaListNotifier extends AsyncNotifier<List<MediaAsset>> {
  @override
  Future<List<MediaAsset>> build() async {
    return ref.watch(mediaRepositoryProvider).getMediaAssets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(mediaRepositoryProvider).getMediaAssets());
  }

  Future<void> deleteAsset(int id) async {
    await ref.read(mediaRepositoryProvider).deleteMediaAsset(id);
    await refresh();
  }
}
