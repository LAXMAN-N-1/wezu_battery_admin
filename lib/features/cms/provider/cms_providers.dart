import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/blog.dart';
import '../data/models/faq.dart';
import '../data/models/banner.dart';
import '../data/models/legal_document.dart';
import '../data/models/media_asset.dart';
import '../data/repositories/cms_repository.dart';
import '../data/repositories/media_repository.dart';
import 'dart:typed_data';

final cmsRepositoryProvider = Provider<CmsRepository>((ref) => CmsRepository());

// ─────────────────────────────────────────
// BLOGS PROVIDER
// ─────────────────────────────────────────

class BlogState {
  final List<Blog> blogs;
  final bool isLoading;
  final String? error;

  BlogState({
    this.blogs = const [],
    this.isLoading = false,
    this.error,
  });

  BlogState copyWith({
    List<Blog>? blogs,
    bool? isLoading,
    String? error,
  }) {
    return BlogState(
      blogs: blogs ?? this.blogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BlogNotifier extends AsyncNotifier<List<Blog>> {
  String _searchQuery = '';
  String? _statusFilter;
  String? _categoryFilter;
  String _sortColumn = 'date';
  bool _sortAscending = false;

  @override
  Future<List<Blog>> build() async {
    return _fetchBlogs();
  }

  Future<List<Blog>> _fetchBlogs() async {
    final repo = ref.read(cmsRepositoryProvider);
    final data = await repo.getBlogs(limit: 1000); // Fetch all for local filtering
    var blogs = data.map((e) => Blog.fromJson(e)).toList();

    // Local Filtering
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      blogs = blogs.where((b) => 
        b.title.toLowerCase().contains(query) || 
        b.slug.toLowerCase().contains(query)
      ).toList();
    }

    if (_statusFilter != null && _statusFilter != 'all') {
      blogs = blogs.where((b) => b.status == _statusFilter).toList();
    }

    if (_categoryFilter != null && _categoryFilter != 'all') {
      blogs = blogs.where((b) => b.category.toLowerCase() == _categoryFilter!.toLowerCase()).toList();
    }

    // Local Sorting
    blogs.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'title':
          cmp = a.title.compareTo(b.title);
          break;
        case 'views':
          cmp = a.viewsCount.compareTo(b.viewsCount);
          break;
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        case 'date':
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return blogs;
  }

  void setSearch(String query) {
    _searchQuery = query;
    _updateState();
  }

  void setFilters({String? status, String? category}) {
    if (status != null) _statusFilter = status;
    if (category != null) _categoryFilter = category;
    _updateState();
  }

  void setSort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = false;
    }
    _updateState();
  }

  Future<void> _updateState() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBlogs());
  }

  Future<void> refresh() async => _updateState();

  Future<void> createBlog(Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.createBlog(data);
    ref.invalidateSelf();
  }

  Future<void> updateBlog(int id, Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateBlog(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteBlog(int id) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.deleteBlog(id);
    ref.invalidateSelf();
  }

  Future<void> toggleStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'published' ? 'draft' : 'published';
    await updateBlog(id, {'status': newStatus});
  }
}

final blogProvider = AsyncNotifierProvider<BlogNotifier, List<Blog>>(BlogNotifier.new);

final blogStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final blogsAsync = ref.watch(blogProvider);
  return blogsAsync.whenData((blogs) {
    return {
      'all': blogs.length,
      'published': blogs.where((b) => b.status == 'published').length,
      'draft': blogs.where((b) => b.status == 'draft').length,
      'scheduled': blogs.where((b) => b.status == 'scheduled').length,
    };
  });
});

// ─────────────────────────────────────────
// FAQS PROVIDER
// ─────────────────────────────────────────

class FaqNotifier extends AsyncNotifier<List<FAQ>> {
  String _searchQuery = '';

  @override
  Future<List<FAQ>> build() async {
    return _fetchFaqs();
  }

  Future<List<FAQ>> _fetchFaqs({String? category}) async {
    final repo = ref.read(cmsRepositoryProvider);
    final data = await repo.getFaqs(category: category);
    var faqs = data.map((e) => FAQ.fromJson(e)).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      faqs = faqs.where((f) => 
        f.question.toLowerCase().contains(query) || 
        f.answer.toLowerCase().contains(query)
      ).toList();
    }

    faqs.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return faqs;
  }

  Future<void> _updateState() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFaqs());
  }

  void setSearch(String query) {
    _searchQuery = query;
    _updateState();
  }

  Future<void> refresh() async => _updateState();

  Future<void> createFaq(Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.createFaq(data);
    ref.invalidateSelf();
  }

  Future<void> updateFaq(int id, Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateFaq(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteFaq(int id) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.deleteFaq(id);
    ref.invalidateSelf();
  }
  
  Future<void> toggleStatus(int id, bool isActive) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateFaqStatus(id, isActive);
    ref.invalidateSelf();
  }

  Future<void> updateOrder(List<int> faqIds) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateFaqOrder(faqIds);
    ref.invalidateSelf();
  }
}

final faqProvider = AsyncNotifierProvider<FaqNotifier, List<FAQ>>(FaqNotifier.new);

// ─────────────────────────────────────────
// BANNERS PROVIDER
// ─────────────────────────────────────────

class BannerNotifier extends AsyncNotifier<List<Banner>> {
  String? _typeFilter;
  String? _statusFilter;

  @override
  Future<List<Banner>> build() async {
    return _fetchBanners();
  }

  Future<List<Banner>> _fetchBanners() async {
    final repo = ref.read(cmsRepositoryProvider);
    final data = await repo.getBanners();
    var banners = data.map((e) => Banner.fromJson(e)).toList();

    // Local Filtering
    if (_typeFilter != null && _typeFilter != 'All') {
      banners = banners.where((b) => b.type == _typeFilter).toList();
    }

    if (_statusFilter != null && _statusFilter != 'All') {
      final now = DateTime.now();
      banners = banners.where((b) {
        if (_statusFilter == 'Active') return b.isActive && (b.startDate == null || b.startDate!.isBefore(now)) && (b.endDate == null || b.endDate!.isAfter(now));
        if (_statusFilter == 'Inactive') return !b.isActive;
        if (_statusFilter == 'Scheduled') return b.isActive && b.startDate != null && b.startDate!.isAfter(now);
        if (_statusFilter == 'Expired') return b.endDate != null && b.endDate!.isBefore(now);
        return true;
      }).toList();
    }

    banners.sort((a, b) => a.priority.compareTo(b.priority));
    return banners;
  }

  void setFilters({String? type, String? status}) {
    if (type != null) _typeFilter = type;
    if (status != null) _statusFilter = status;
    ref.invalidateSelf();
  }

  Future<void> toggleBanner(int id, bool isActive) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateBanner(id, {'is_active': isActive});
    ref.invalidateSelf();
  }

  Future<void> deleteBanner(int id) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.deleteBanner(id);
    ref.invalidateSelf();
  }
}

final bannerProvider = AsyncNotifierProvider<BannerNotifier, List<Banner>>(BannerNotifier.new);

// ─────────────────────────────────────────
// LEGAL DOCS PROVIDER
// ─────────────────────────────────────────

class LegalNotifier extends AsyncNotifier<List<LegalDocument>> {
  @override
  Future<List<LegalDocument>> build() async {
    return _fetchDocs();
  }

  Future<List<LegalDocument>> _fetchDocs() async {
    final repo = ref.read(cmsRepositoryProvider);
    final data = await repo.getLegalDocs();
    return data.map((e) => LegalDocument.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDocs());
  }

  Future<void> updateDoc(int id, Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateLegalDoc(id, data);
    ref.invalidateSelf();
  }

  Future<void> createDoc(Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.createLegalDoc(data);
    ref.invalidateSelf();
  }

  Future<void> publishNewVersion(int id, Map<String, dynamic> data) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.updateLegalDoc(id, {
      ...data,
      'status': 'PUBLISHED',
      'is_active': true,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteDoc(int id) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.deleteLegalDoc(id);
    ref.invalidateSelf();
  }
}

final legalProvider = AsyncNotifierProvider<LegalNotifier, List<LegalDocument>>(LegalNotifier.new);

// ─────────────────────────────────────────
// MEDIA ASSETS PROVIDER
// ─────────────────────────────────────────

class MediaNotifier extends AsyncNotifier<List<MediaAsset>> {
  String? _searchQuery;
  String? _typeFilter;
  String? _currentFolderPath;

  @override
  Future<List<MediaAsset>> build() async {
    return _fetchMedia();
  }

  Future<List<MediaAsset>> _fetchMedia({String? category}) async {
    final repo = ref.read(mediaRepositoryProvider);
    var assets = await repo.getMediaAssets(category: category);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      assets = assets.where((a) => a.fileName.toLowerCase().contains(_searchQuery!.toLowerCase())).toList();
    }

    if (_typeFilter != null && _typeFilter != 'All') {
      assets = assets.where((a) {
        if (_typeFilter == 'Images') return a.isImage;
        if (_typeFilter == 'Videos') return a.isVideo;
        if (_typeFilter == 'PDFs') return a.isPdf;
        return true;
      }).toList();
    }

    if (_currentFolderPath != null) {
      assets = assets.where((a) => a.folderPath == _currentFolderPath).toList();
    }

    return assets;
  }

  void setFolder(String? path) {
    _currentFolderPath = path;
    ref.invalidateSelf();
  }

  void setSearch(String query) {
    _searchQuery = query;
    ref.invalidateSelf();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    ref.invalidateSelf();
  }

  Future<void> refresh({String? category}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMedia(category: category));
  }

  Future<void> uploadFile({
    required List<int> bytes,
    required String fileName,
    String? category,
    String? altText,
  }) async {
    final repo = ref.read(mediaRepositoryProvider);
    await repo.uploadMedia(
      bytes,
      fileName,
      category: category ?? 'general',
      altText: altText,
    );
    ref.invalidateSelf();
  }

  Future<void> uploadAsset({
    required String fileName,
    required String fileType,
    required int fileSize,
    required String url,
    String? altText,
    String? category,
    String? folderPath,
  }) async {
    final repo = ref.read(cmsRepositoryProvider);
    await repo.createMediaAsset(
      fileName: fileName,
      fileType: fileType,
      fileSizeBytes: fileSize,
      url: url,
      altText: altText,
      category: category ?? 'general',
      folderPath: folderPath,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteAsset(int id) async {
    final repo = ref.read(mediaRepositoryProvider);
    await repo.deleteMediaAsset(id);
    ref.invalidateSelf();
  }
}

final mediaProvider = AsyncNotifierProvider<MediaNotifier, List<MediaAsset>>(MediaNotifier.new);
