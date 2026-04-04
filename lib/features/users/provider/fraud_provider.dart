import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/fraud_repository.dart';
import '../data/models/fraud_risk.dart';
import '../data/models/duplicate_account.dart';
import '../data/models/blacklist_entry.dart';

// ─── State ───────────────────────────────────────────────────────────

class FraudState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  // High risk users list
  final List<FraudRisk> highRiskUsers;
  final double riskThreshold;

  // Selected user risk detail
  final FraudRisk? selectedUserRisk;
  final int? selectedUserId;

  // Duplicate accounts
  final List<DuplicateAccount> duplicateAccounts;
  final String? duplicateStatusFilter;

  // Blacklist
  final List<BlacklistEntry> blacklist;
  final String? blacklistTypeFilter;

  // Device fingerprints
  final List<Map<String, dynamic>> deviceFingerprints;
  final bool showSuspiciousOnly;

  // Active tab
  final int activeTab;

  FraudState({
    this.isLoading = true,
    this.error,
    this.successMessage,
    this.highRiskUsers = const [],
    this.riskThreshold = 50,
    this.selectedUserRisk,
    this.selectedUserId,
    this.duplicateAccounts = const [],
    this.duplicateStatusFilter,
    this.blacklist = const [],
    this.blacklistTypeFilter,
    this.deviceFingerprints = const [],
    this.showSuspiciousOnly = false,
    this.activeTab = 0,
  });

  FraudState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<FraudRisk>? highRiskUsers,
    double? riskThreshold,
    FraudRisk? selectedUserRisk,
    int? selectedUserId,
    List<DuplicateAccount>? duplicateAccounts,
    String? duplicateStatusFilter,
    List<BlacklistEntry>? blacklist,
    String? blacklistTypeFilter,
    List<Map<String, dynamic>>? deviceFingerprints,
    bool? showSuspiciousOnly,
    int? activeTab,
    bool clearSelectedUser = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FraudState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      highRiskUsers: highRiskUsers ?? this.highRiskUsers,
      riskThreshold: riskThreshold ?? this.riskThreshold,
      selectedUserRisk: clearSelectedUser ? null : (selectedUserRisk ?? this.selectedUserRisk),
      selectedUserId: clearSelectedUser ? null : (selectedUserId ?? this.selectedUserId),
      duplicateAccounts: duplicateAccounts ?? this.duplicateAccounts,
      duplicateStatusFilter: duplicateStatusFilter ?? this.duplicateStatusFilter,
      blacklist: blacklist ?? this.blacklist,
      blacklistTypeFilter: blacklistTypeFilter ?? this.blacklistTypeFilter,
      deviceFingerprints: deviceFingerprints ?? this.deviceFingerprints,
      showSuspiciousOnly: showSuspiciousOnly ?? this.showSuspiciousOnly,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────

class FraudNotifier extends StateNotifier<FraudState> {
  final FraudRepository _repository;

  FraudNotifier(this._repository) : super(FraudState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.getHighRiskUsers(threshold: state.riskThreshold),
        _repository.getDuplicateAccounts(status: state.duplicateStatusFilter),
        _repository.getBlacklist(type: state.blacklistTypeFilter),
        _repository.getDeviceFingerprints(suspiciousOnly: state.showSuspiciousOnly),
      ]);
      state = state.copyWith(
        isLoading: false,
        highRiskUsers: results[0] as List<FraudRisk>,
        duplicateAccounts: results[1] as List<DuplicateAccount>,
        blacklist: results[2] as List<BlacklistEntry>,
        deviceFingerprints: results[3] as List<Map<String, dynamic>>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setActiveTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  // ─── High Risk Users ──────────────────────────────────────────────

  Future<void> refreshHighRiskUsers({double? threshold}) async {
    if (threshold != null) state = state.copyWith(riskThreshold: threshold);
    try {
      final users = await _repository.getHighRiskUsers(
        threshold: threshold ?? state.riskThreshold,
      );
      state = state.copyWith(highRiskUsers: users);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> selectUser(int userId) async {
    state = state.copyWith(selectedUserId: userId);
    try {
      final risk = await _repository.getUserRiskScore(userId);
      state = state.copyWith(selectedUserRisk: risk);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearSelectedUser() {
    state = state.copyWith(clearSelectedUser: true);
  }

  // ─── Duplicate Accounts ───────────────────────────────────────────

  Future<void> refreshDuplicateAccounts({String? status}) async {
    state = state.copyWith(duplicateStatusFilter: status);
    try {
      final dupes = await _repository.getDuplicateAccounts(status: status);
      state = state.copyWith(duplicateAccounts: dupes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> handleDuplicateAccount(int id, {required String action, String? notes}) async {
    try {
      await _repository.handleDuplicateAccount(id, action: action, notes: notes);
      state = state.copyWith(successMessage: 'Action taken on duplicate account');
      await refreshDuplicateAccounts(status: state.duplicateStatusFilter);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ─── Blacklist ────────────────────────────────────────────────────

  Future<void> refreshBlacklist({String? type}) async {
    state = state.copyWith(blacklistTypeFilter: type);
    try {
      final list = await _repository.getBlacklist(type: type);
      state = state.copyWith(blacklist: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addToBlacklist({
    required String type,
    required String value,
    required String reason,
  }) async {
    try {
      await _repository.addToBlacklist(type: type, value: value, reason: reason);
      state = state.copyWith(successMessage: 'Added to blacklist');
      await refreshBlacklist(type: state.blacklistTypeFilter);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeFromBlacklist(int id) async {
    try {
      await _repository.removeFromBlacklist(id);
      state = state.copyWith(successMessage: 'Removed from blacklist');
      await refreshBlacklist(type: state.blacklistTypeFilter);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ─── Device Fingerprints ──────────────────────────────────────────

  Future<void> refreshDeviceFingerprints({int? userId, bool? suspiciousOnly}) async {
    if (suspiciousOnly != null) state = state.copyWith(showSuspiciousOnly: suspiciousOnly);
    try {
      final fps = await _repository.getDeviceFingerprints(
        userId: userId,
        suspiciousOnly: suspiciousOnly ?? state.showSuspiciousOnly,
      );
      state = state.copyWith(deviceFingerprints: fps);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ─── Verification ─────────────────────────────────────────────────

  Future<dynamic> verifyPan({required String panNumber, required String name}) async {
    try {
      final result = await _repository.verifyPan(panNumber: panNumber, name: name);
      state = state.copyWith(successMessage: 'PAN verification complete');
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<dynamic> verifyGst({required String gstNumber, required String businessName}) async {
    try {
      final result = await _repository.verifyGst(gstNumber: gstNumber, businessName: businessName);
      state = state.copyWith(successMessage: 'GST verification complete');
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<dynamic> verifyPhone({required String phoneNumber}) async {
    try {
      final result = await _repository.verifyPhone(phoneNumber: phoneNumber);
      state = state.copyWith(successMessage: 'Phone verification complete');
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final fraudProvider = StateNotifierProvider<FraudNotifier, FraudState>((ref) {
  return FraudNotifier(ref.watch(fraudRepositoryProvider));
});
