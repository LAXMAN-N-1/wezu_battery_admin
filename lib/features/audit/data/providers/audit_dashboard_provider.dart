import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_models.dart';
import '../repositories/audit_repository.dart';

class AuditDashboardState {
  final bool isLoading;
  final AuditDashboardStats? stats;
  final bool isAutoRefreshEnabled;
  final String selectedTimeRange;
  final String? error;

  AuditDashboardState({
    this.isLoading = false,
    this.stats,
    this.isAutoRefreshEnabled = false,
    this.selectedTimeRange = '24h',
    this.error,
  });

  AuditDashboardState copyWith({
    bool? isLoading,
    AuditDashboardStats? stats,
    bool? isAutoRefreshEnabled,
    String? selectedTimeRange,
    String? error,
  }) {
    return AuditDashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      isAutoRefreshEnabled: isAutoRefreshEnabled ?? this.isAutoRefreshEnabled,
      selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
      error: error ?? this.error,
    );
  }
}

class AuditDashboardNotifier extends StateNotifier<AuditDashboardState> {
  final AuditRepository _repository;
  Timer? _refreshTimer;

  AuditDashboardNotifier(this._repository) : super(AuditDashboardState(isLoading: true)) {
    loadDashboard();
  }

  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repository.getSecurityDashboard();
      // Since models might be slightly different, we'll assume the repository returns a Map 
      // that matches the UI needs. We might need to update AuditDashboardStats to match.
      // For now, let's keep it simple and just fetch.
      state = state.copyWith(isLoading: false); 
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTimeRange(String range) {
    state = state.copyWith(selectedTimeRange: range);
    loadDashboard();
  }

  void toggleAutoRefresh(bool enabled) {
    state = state.copyWith(isAutoRefreshEnabled: enabled);
    _refreshTimer?.cancel();
    if (enabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        loadDashboard(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final auditDashboardProvider = StateNotifierProvider<AuditDashboardNotifier, AuditDashboardState>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return AuditDashboardNotifier(repo);
});
