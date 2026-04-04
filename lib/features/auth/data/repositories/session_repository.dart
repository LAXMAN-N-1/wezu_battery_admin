import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/user_session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(apiClientProvider));
});

class SessionRepository {
  final ApiClient _api;

  SessionRepository(this._api);

  /// List all active sessions for the current user.
  Future<List<UserSession>> listSessions() async {
    try {
      final response = await _api.get('/api/v1/sessions/list');
      if (response.data is List) {
        return (response.data as List).map((json) => UserSession.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Revoke a specific session.
  Future<void> revokeSession(int sessionId) async {
    try {
      await _api.post('/api/v1/sessions/revoke/$sessionId');
    } catch (e) {
      rethrow;
    }
  }
}
