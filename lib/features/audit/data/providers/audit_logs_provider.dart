import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_models.dart';
import '../repositories/audit_repository.dart';

class AuditLogsState {
  final bool isLoading;
  final bool isMoreLoading;
  final List<AuditLogItem> logs;
  final int totalCount;
  final String? filterAction;
  final String? filterSeverity;
  final String? filterStatus;
  final String? search;
  final DateTimeRange? dateRange;
  final String? error;
  final Set<int> newLogIds;
  final bool isAutoRefreshEnabled;

  AuditLogsState({
    this.isLoading = false,
    this.isMoreLoading = false,
    this.logs = const [],
    this.totalCount = 0,
    this.filterAction,
    this.filterSeverity,
    this.filterStatus,
    this.search,
    this.dateRange,
    this.error,
    this.newLogIds = const {},
    this.isAutoRefreshEnabled = false,
  });

  AuditLogsState copyWith({
    bool? isLoading,
    bool? isMoreLoading,
    List<AuditLogItem>? logs,
    int? totalCount,
    String? filterAction,
    String? filterSeverity,
    String? filterStatus,
    String? search,
    DateTimeRange? dateRange,
    String? error,
    Set<int>? newLogIds,
    bool? isAutoRefreshEnabled,
  }) {
    return AuditLogsState(
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      logs: logs ?? this.logs,
      totalCount: totalCount ?? this.totalCount,
      filterAction: filterAction ?? this.filterAction,
      filterSeverity: filterSeverity ?? this.filterSeverity,
      filterStatus: filterStatus ?? this.filterStatus,
      search: search ?? this.search,
      dateRange: dateRange ?? this.dateRange,
      error: error ?? this.error,
      newLogIds: newLogIds ?? this.newLogIds,
      isAutoRefreshEnabled: isAutoRefreshEnabled ?? this.isAutoRefreshEnabled,
    );
  }

  AuditLogsState resetFilters() {
    return AuditLogsState(isAutoRefreshEnabled: isAutoRefreshEnabled);
  }
}

class AuditLogsNotifier extends StateNotifier<AuditLogsState> {
  final AuditRepository _repository;

  AuditLogsNotifier(this._repository) : super(AuditLogsState()) {
    loadLogs();
  }

  Future<void> loadLogs({bool refresh = true}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, logs: [], error: null);
    } else {
      if (state.isMoreLoading || state.logs.length >= state.totalCount) return;
      state = state.copyWith(isMoreLoading: true);
    }

    try {
      final res = await _repository.getAuditLogs(
        action: state.filterAction,
        severity: state.filterSeverity,
        status: state.filterStatus,
        search: state.search,
        startDate: state.dateRange?.start.toIso8601String(),
        endDate: state.dateRange?.end.toIso8601String(),
        skip: refresh ? 0 : state.logs.length,
        limit: 50,
      );

      final newLogs = res['items'] as List<AuditLogItem>;
      state = state.copyWith(
        isLoading: false,
        isMoreLoading: false,
        logs: refresh ? newLogs : [...state.logs, ...newLogs],
        totalCount: res['total_count'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isMoreLoading: false, error: e.toString());
    }
  }

  void setFilterAction(String? action) {
    state = state.copyWith(filterAction: action);
    loadLogs();
  }

  void setFilterSeverity(String? severity) {
    state = state.copyWith(filterSeverity: severity);
    loadLogs();
  }

  void setFilterStatus(String? status) {
    state = state.copyWith(filterStatus: status);
    loadLogs();
  }

  void setSearch(String? query) {
    state = state.copyWith(search: query);
    loadLogs();
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
    loadLogs();
  }

  void clearFilters() {
    state = state.resetFilters();
    loadLogs();
  }

  void prependEvent(AuditLogItem event) {
    state = state.copyWith(
      logs: [event, ...state.logs],
      totalCount: state.totalCount + 1,
      newLogIds: {event.id, ...state.newLogIds},
    );
    
    // Clear the highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(
          newLogIds: state.newLogIds.where((id) => id != event.id).toSet(),
        );
      }
    });
  }

  Future<void> flagAsSuspicious(int id, {bool isSuspicious = true}) async {
    try {
      await _repository.flagAuditLogSuspicious(id, isSuspicious: isSuspicious);
      // Update local state
      state = state.copyWith(
        logs: state.logs.map((e) => e.id == id ? e.copyWith(isSuspicious: isSuspicious) : e).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to flag log: $e');
    }
  }

  Future<void> toggleSuspicious(int id) async {
    final log = state.logs.where((e) => e.id == id).firstOrNull;
    if (log != null) {
      await flagAsSuspicious(id, isSuspicious: !log.isSuspicious);
    }
  }
}

final auditLogsProvider = StateNotifierProvider<AuditLogsNotifier, AuditLogsState>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return AuditLogsNotifier(repo);
});
