import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_models.dart';
import '../repositories/audit_repository.dart';


class SecurityEventsState {
  final bool isLoading;
  final List<SecurityEventItem> events;
  final String? filterSeverity;
  final bool? filterResolved;
  final String? error;

  SecurityEventsState({
    this.isLoading = false,
    this.events = const [],
    this.filterSeverity,
    this.filterResolved,
    this.error,
  });

  SecurityEventsState copyWith({
    bool? isLoading,
    List<SecurityEventItem>? events,
    String? filterSeverity,
    bool? filterResolved,
    String? error,
  }) {
    return SecurityEventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      filterSeverity: filterSeverity ?? this.filterSeverity,
      filterResolved: filterResolved ?? this.filterResolved,
      error: error ?? this.error,
    );
  }
}

class SecurityEventsNotifier extends StateNotifier<SecurityEventsState> {
  final AuditRepository _repository;

  SecurityEventsNotifier(this._repository) : super(SecurityEventsState()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repository.getSecurityEvents(
        severity: state.filterSeverity,
        // Removed unsupported isResolved parameter to align with current repository signature
      );
      state = state.copyWith(
        isLoading: false,
        events: res['items'] as List<SecurityEventItem>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilterSeverity(String? severity) {
    state = state.copyWith(filterSeverity: severity);
    loadEvents();
  }

  void setFilterResolved(bool? resolved) {
    state = state.copyWith(filterResolved: resolved);
    loadEvents();
  }

  Future<void> resolveEvent(int id) async {
    try {
      await _repository.resolveSecurityEvent(id);
      loadEvents();
    } catch (e) {
      state = state.copyWith(error: 'Failed to resolve event: $e');
    }
  }
}

final securityEventsProvider = StateNotifierProvider<SecurityEventsNotifier, SecurityEventsState>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return SecurityEventsNotifier(repo);
});
