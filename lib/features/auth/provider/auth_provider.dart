import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

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
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await _apiClient.storage.read(key: 'admin_token');
    if (token != null) {
      // Potentially fetch user profile here to verify token
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/token',
        data: {
          'grant_type': 'password',
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];
        final user = response.data['user'];

        await _apiClient.storage.write(key: 'admin_token', value: accessToken);
        if (refreshToken != null) {
          await _apiClient.storage.write(key: 'admin_refresh_token', value: refreshToken);
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user is Map<String, dynamic> ? user : null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Login failed');
      }
    } on DioException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your internet or server status.';
      } else if (e.response?.data is Map) {
        final detail = e.response?.data['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List && detail.isNotEmpty) {
          errorMessage = detail[0]['msg'] ?? 'Validation error';
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  Future<void> logout() async {
    await _apiClient.storage.delete(key: 'admin_token');
    await _apiClient.storage.delete(key: 'admin_refresh_token');
    state = state.copyWith(isAuthenticated: false, user: null);
  }
}
