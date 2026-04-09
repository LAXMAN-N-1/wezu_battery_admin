import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_models.dart';
import '../repositories/audit_repository.dart';

class FraudState {
  final bool isLoading;
  final List<FraudAlertItem> alerts;
  final List<dynamic> highRiskUsers;
  final List<dynamic> duplicateAccounts;
  final int totalAlerts;
  final String? filterStatus;
  final int highRiskCount;
  final int investigatingCount;
  final int resolvedCount;
  final String? error;

  FraudState({
    this.isLoading = false,
    this.alerts = const [],
    this.highRiskUsers = const [],
    this.duplicateAccounts = const [],
    this.totalAlerts = 0,
    this.highRiskCount = 0,
    this.investigatingCount = 0,
    this.resolvedCount = 0,
    this.filterStatus,
    this.error,
  });

  FraudState copyWith({
    bool? isLoading,
    List<FraudAlertItem>? alerts,
    List<dynamic>? highRiskUsers,
    List<dynamic>? duplicateAccounts,
    int? totalAlerts,
    int? highRiskCount,
    int? investigatingCount,
    int? resolvedCount,
    String? filterStatus,
    String? error,
  }) {
    return FraudState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      highRiskUsers: highRiskUsers ?? this.highRiskUsers,
      duplicateAccounts: duplicateAccounts ?? this.duplicateAccounts,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      highRiskCount: highRiskCount ?? this.highRiskCount,
      investigatingCount: investigatingCount ?? this.investigatingCount,
      resolvedCount: resolvedCount ?? this.resolvedCount,
      filterStatus: filterStatus ?? this.filterStatus,
      error: error ?? this.error,
    );
  }
}

class FraudNotifier extends StateNotifier<FraudState> {
  final AuditRepository _repository;

  FraudNotifier(this._repository) : super(FraudState()) {
    refreshAll();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.wait([
      loadAlerts(refresh: true),
      loadHighRiskUsers(),
      loadDuplicateAccounts(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadAlerts({bool refresh = true}) async {
    if (refresh) {
      state = state.copyWith(alerts: [], error: null);
    }

    try {
      final res = await _repository.getFraudAlerts(
        status: state.filterStatus,
        skip: refresh ? 0 : state.alerts.length,
      );

      final newAlerts = res['items'] as List<FraudAlertItem>;
      final allAlerts = refresh ? newAlerts : [...state.alerts, ...newAlerts];
      
      // Calculate summary stats
      int high = allAlerts.where((e) => e.riskScore > 80 && e.status != 'Resolved').length;
      int inv = allAlerts.where((e) => e.status == 'Investigation').length;
      int resCount = allAlerts.where((e) => e.status == 'Resolved').length;

      state = state.copyWith(
        isLoading: false,
        alerts: allAlerts,
        totalAlerts: res['total_count'] ?? 0,
        highRiskCount: high,
        investigatingCount: inv,
        resolvedCount: resCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadHighRiskUsers() async {
    try {
      final res = await _repository.getHighRiskUsers();
      state = state.copyWith(highRiskUsers: res['items'] as List<dynamic>);
    } catch (e) {
      // Non-blocking error
      debugPrint('Error loading high risk users: $e');
    }
  }

  Future<void> loadDuplicateAccounts() async {
    try {
      final res = await _repository.getDuplicateAccounts();
      state = state.copyWith(duplicateAccounts: res['items'] as List<dynamic>);
    } catch (e) {
      // Non-blocking error
      debugPrint('Error loading duplicate accounts: $e');
    }
  }

  void setFilterStatus(String? status) {
    state = state.copyWith(filterStatus: status);
    loadAlerts();
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _repository.updateFraudAlertStatus(id, status);
      loadAlerts();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update status: $e');
    }
  }

  Future<void> escalate(String id) async {
    try {
      await _repository.escalateFraudAlert(id);
      loadAlerts();
    } catch (e) {
      state = state.copyWith(error: 'Failed to escalate: $e');
    }
  }
}

final fraudProvider = StateNotifierProvider<FraudNotifier, FraudState>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return FraudNotifier(repo);
});
