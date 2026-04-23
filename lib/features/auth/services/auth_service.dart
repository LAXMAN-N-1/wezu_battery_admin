import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<String?> getValidAccessToken() async {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  Future<void> clearSessionAndRedirect() async {
    await _apiClient.clearSession(notifyListeners: true);
  }
}
