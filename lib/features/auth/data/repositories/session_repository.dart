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
    final endpoints = <String>[
      '/api/v1/sessions/list',
      '/api/v1/admin/sessions',
      '/api/v1/admin/users/me/sessions',
    ];

    Object? lastError;
    for (final path in endpoints) {
      try {
        final response = await _api.get(path);
        final data = response.data;

        if (data is List) {
          return data
              .whereType<Map>()
              .map(
                (json) => UserSession.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        }
        if (data is Map && data['items'] is List) {
          final items = (data['items'] as List).whereType<Map>();
          return items
              .map(
                (json) => UserSession.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    return [];
  }

  /// Revoke a specific session.
  Future<void> revokeSession(int sessionId) async {
    final endpoints = <String>[
      '/api/v1/sessions/revoke/$sessionId',
      '/api/v1/admin/sessions/$sessionId/revoke',
    ];

    Object? lastError;
    for (final path in endpoints) {
      try {
        await _api.post(path);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
  }
}
