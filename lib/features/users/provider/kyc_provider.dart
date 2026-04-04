import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/kyc_document.dart';
import '../data/repositories/kyc_repository.dart';

class KycState {
  final Map<String, dynamic> dashboard;
  final List<dynamic> pendingQueue;
  final List<KycDocument> documents;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final int totalPending;
  final int skip;
  final int limit;
  final int currentPage;
  final String? filterStatus;
  final String searchQuery;

  KycState({
    this.dashboard = const {},
    this.pendingQueue = const [],
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.totalPending = 0,
    this.skip = 0,
    this.limit = 50,
    this.currentPage = 1,
    this.filterStatus,
    this.searchQuery = '',
  });

  KycState copyWith({
    Map<String, dynamic>? dashboard,
    List<dynamic>? pendingQueue,
    List<KycDocument>? documents,
    bool? isLoading,
    String? error,
    int? totalCount,
    int? totalPending,
    int? skip,
    int? limit,
    int? currentPage,
    String? filterStatus,
    String? searchQuery,
  }) {
    return KycState(
      dashboard: dashboard ?? this.dashboard,
      pendingQueue: pendingQueue ?? this.pendingQueue,
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      totalPending: totalPending ?? this.totalPending,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      currentPage: currentPage ?? this.currentPage,
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class KycNotifier extends StateNotifier<KycState> {
  final KycRepository _repository;

  KycNotifier(this._repository) : super(KycState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getKycDashboard();
      state = state.copyWith(isLoading: false, dashboard: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPendingQueue({int page = 1, int size = 10, String? userType}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getPendingKycQueue(page: page, size: size, userType: userType);
      state = state.copyWith(
        isLoading: false,
        pendingQueue: data['items'] ?? [],
        totalPending: data['total'] ?? 0,
        currentPage: data['page'] ?? page,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDocuments({int? skip, int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final s = skip ?? state.skip;
      final l = limit ?? state.limit;
      final docs = await _repository.listKycDocuments(
        skip: s,
        limit: l,
        status: state.filterStatus,
        search: state.searchQuery,
      );
      state = state.copyWith(
        isLoading: false,
        documents: docs,
        totalCount: docs.length,
        skip: s,
        limit: l,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilterStatus(String? status) {
    state = state.copyWith(filterStatus: status, skip: 0);
    loadDocuments();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, skip: 0);
    loadDocuments();
  }

  Future<void> approveDocument(int docId) async {
    try {
      await _repository.approveDocument(docId);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectDocument(int docId, String reason) async {
    try {
      await _repository.rejectDocument(docId, reason);
      // New spec returns document info, but we refresh the list
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> finalizeVerification(int userId, String decision, String notes) async {
    try {
      await _repository.verifyKycSubmission(userId, decision: decision, notes: notes);
      await loadPendingQueue(); // Refresh queue
      await loadDashboard();    // Refresh counts
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.wait([
      loadDashboard(),
      loadPendingQueue(),
      loadDocuments(),
    ]);
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref.watch(kycRepositoryProvider));
});
