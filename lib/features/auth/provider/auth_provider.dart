import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _apiClient.onUnauthorized = logout;
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    state = state.copyWith(isLoading: true);

    final token = await _apiClient.storage.read(key: 'admin_token');
    if (token != null) {
      try {
        // Verify token by fetching current user profile
        final response = await _apiClient.get('customer/users/me');
        if (response.statusCode == 200) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: response.data,
          );
        } else {
          await logout();
        }
      } catch (e) {
        // If 401 or network error, assume not authenticated for safety
        await logout();
      }
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final formData = FormData.fromMap({
        'username': email,
        'password': password,
      });

      final response = await _apiClient.post(
        '/api/v1/auth/admin/login',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'];

        await _apiClient.storage.write(key: 'admin_token', value: token);
        _apiClient.dio.options.headers['Authorization'] = 'Bearer $token';

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: data['user'],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please check your credentials.',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred.';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? 'Network error occurred.';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> logout() async {
    await _apiClient.storage.delete(key: 'admin_token');
    _apiClient.dio.options.headers.remove('Authorization');
    // Invalidate the apiClientProvider to ensure a fresh instance without old headers
    // This requires access to ref, which is not directly available in StateNotifier.
    // A common pattern is to pass ref or a callback to invalidate.
    // For now, we'll just remove the header and clear state.
    // If `ref.invalidate(apiClientProvider)` is truly needed, the AuthNotifier
    // would need to be refactored to receive `ref` or a specific invalidation callback.
    state = state.copyWith(
      isAuthenticated: false,
      user: null,
      error: null,
      isLoading: false,
    );
  }
}
