import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../data/models/audit_log.dart';
import '../data/repositories/audit_log_repository.dart';

final auditRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(apiClientProvider));
});

class AuditState {
  final List<AuditLog> logs;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final int page;

  AuditState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.page = 1,
  });

  AuditState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
    String? error,
    int? totalCount,
    int? page,
  }) {
    return AuditState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
    );
  }
}

class AuditNotifier extends StateNotifier<AuditState> {
  final AuditLogRepository _repository;

  AuditNotifier(this._repository) : super(AuditState());

  Future<void> loadLogs({
    String? action,
    String? module,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final logs = await _repository.getLogs(
        action: action,
        module: module,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );
      state = state.copyWith(isLoading: false, logs: logs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadRoleChanges(int roleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final logs = await _repository.getRoleAuditLog(roleId);
      state = state.copyWith(isLoading: false, logs: logs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUserLogs(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final logs = await _repository.getUserAuditLog(userId);
      state = state.copyWith(isLoading: false, logs: logs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final auditProvider = StateNotifierProvider<AuditNotifier, AuditState>((ref) {
  return AuditNotifier(ref.watch(auditRepositoryProvider));
});

// Specific provider for role audit logs in RolesPermissionsView
final roleAuditProvider = StateNotifierProvider.family<AuditNotifier, AuditState, int>((ref, roleId) {
  final notifier = AuditNotifier(ref.watch(auditRepositoryProvider));
  notifier.loadRoleChanges(roleId);
  return notifier;
});
