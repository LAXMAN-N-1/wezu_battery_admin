import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/kyc_document.dart';
import '../data/repositories/kyc_repository.dart';

class KycState {
  final Map<String, dynamic> dashboard;
  final List<dynamic> pendingQueue;
  final List<KycDocument> pendingDocuments;
  final bool isLoading;
  final String? error;
  final int totalPending;
  final int currentPage;

  KycState({
    this.dashboard = const {},
    this.pendingQueue = const [],
    this.pendingDocuments = const [],
    this.isLoading = false,
    this.error,
    this.totalPending = 0,
    this.currentPage = 1,
  });

  KycState copyWith({
    Map<String, dynamic>? dashboard,
    List<dynamic>? pendingQueue,
    List<KycDocument>? pendingDocuments,
    bool? isLoading,
    String? error,
    int? totalPending,
    int? currentPage,
  }) {
    return KycState(
      dashboard: dashboard ?? this.dashboard,
      pendingQueue: pendingQueue ?? this.pendingQueue,
      pendingDocuments: pendingDocuments ?? this.pendingDocuments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPending: totalPending ?? this.totalPending,
      currentPage: currentPage ?? this.currentPage,
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
      final data = await _repository.getPendingQueue(page: page, size: size, userType: userType);
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

  Future<void> loadPendingDocuments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final docs = await _repository.getPendingDocuments();
      state = state.copyWith(isLoading: false, pendingDocuments: docs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> approveDocument(int docId) async {
    try {
      await _repository.approveDocument(docId);
      await loadPendingDocuments(); // Refresh documents
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectDocument(int docId, String reason) async {
    try {
      await _repository.rejectDocument(docId, reason);
      await loadPendingDocuments(); // Refresh documents
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
      loadPendingDocuments(),
    ]);
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref.watch(kycRepositoryProvider));
});
