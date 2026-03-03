import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kyc_model.dart';
import '../models/user_model.dart';

class KycState {
  final List<KycRequest> requests;
  final bool isLoading;
  final KycStatus? statusFilter;
  final Map<String, dynamic> analytics;

  KycState({
    this.requests = const [],
    this.isLoading = false,
    this.statusFilter,
    this.analytics = const {},
  });

  KycState copyWith({
    List<KycRequest>? requests,
    bool? isLoading,
    KycStatus? statusFilter,
    Map<String, dynamic>? analytics,
  }) {
    return KycState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      statusFilter: statusFilter ?? this.statusFilter,
      analytics: analytics ?? this.analytics,
    );
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier();
});

class KycNotifier extends StateNotifier<KycState> {
  KycNotifier() : super(KycState(isLoading: true)) {
    loadQueue();
  }

  Future<void> loadAnalytics() async {
    loadQueue();
  }

  Future<void> loadQueue() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.delayed(const Duration(milliseconds: 900));
      
      // Mock Data
      final requests = List.generate(15, (index) {
        return KycRequest(
          id: 'KYC-${5000 + index}',
          userId: 'USER-${1000 + index}',
          userName: 'Applicant ${index + 1}',
          documentType: DocumentType.values[index % DocumentType.values.length],
          documentUrls: ['https://via.placeholder.com/600x400', 'https://via.placeholder.com/600x400'],
          status: KycStatus.values[index % KycStatus.values.length], // Use KycStatus
          submittedAt: DateTime.now().subtract(Duration(hours: index * 5)),
        );
      });

      // Filter if needed
      final filtered = state.statusFilter != null 
          ? requests.where((r) => r.status == state.statusFilter).toList()
          : requests;

      final analytics = {
        'pending': requests.where((r) => r.status == KycStatus.pending).length,
        'approved_today': 5, // Mock
        'rejected_today': 2, // Mock
        'avg_time': '45m',
      };

      state = state.copyWith(
        requests: filtered,
        isLoading: false,
        analytics: analytics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setStatusFilter(KycStatus? status) {
     state = KycState(
       requests: state.requests,
       isLoading: state.isLoading,
       statusFilter: status,
       analytics: state.analytics,
     );
     loadQueue();
  }

  Future<void> approveRequest(String id) async {
    loadQueue();
  }

  Future<void> rejectRequest(String id, String reason) async {
    loadQueue();
  }

  void selectRequest(KycRequest request) {
    // Logic to select request, if needed. For now, it can be empty or log.
  }
}
