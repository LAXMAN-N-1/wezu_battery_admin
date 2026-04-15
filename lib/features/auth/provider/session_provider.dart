import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_session.dart';
import '../data/repositories/session_repository.dart';

class SessionState {
  final List<UserSession> sessions;
  final bool isLoading;
  final String? error;

  SessionState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  SessionState copyWith({
    List<UserSession>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionRepository _repository;

  SessionNotifier(this._repository) : super(SessionState());

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _repository.listSessions();
      state = state.copyWith(isLoading: false, sessions: sessions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> revokeSession(int sessionId) async {
    try {
      await _repository.revokeSession(sessionId);
      await loadSessions(); // Refresh list after revocation
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(sessionRepositoryProvider));
});
