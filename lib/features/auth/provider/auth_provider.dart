import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

const _authFieldUnset = Object();

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
    Object? error = _authFieldUnset,
    Object? user = _authFieldUnset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: identical(error, _authFieldUnset) ? this.error : error as String?,
      user: identical(user, _authFieldUnset)
          ? this.user
          : user as Map<String, dynamic>?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._apiClient) : super(AuthState()) {
    _checkStatus();
  }

  final ApiClient _apiClient;

  static const _adminRoles = <String>{'admin', 'super_admin', 'superadmin'};

  Future<void> _checkStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await _apiClient.storage.read(key: 'admin_token');

    if (token != null) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return;
    }

    state = state.copyWith(isLoading: false, isAuthenticated: false);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final username = email.trim();

    try {
      final result = await _authenticate(username, password);
      await _persistSession(result);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
        user: result.user,
      );
    } on _AuthFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.message,
        user: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: _extractErrorMessage(e),
        user: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Unable to sign in right now. Please try again.',
        user: null,
      );
    }
  }

  Future<void> logout() async {
    await _apiClient.storage.delete(key: 'admin_token');
    await _apiClient.storage.delete(key: 'admin_refresh_token');

    state = state.copyWith(isAuthenticated: false, error: null, user: null);
  }

  Future<_AuthResult> _authenticate(String username, String password) async {
    final attempts = <Future<_AuthResult> Function()>[
      () => _loginWithJson(
        path: '/api/v1/auth/admin/login',
        payload: {'username': username, 'password': password},
        allowAdminRoleRetry: false,
      ),
      () => _loginWithJson(
        path: '/api/v1/auth/login',
        payload: {'username': username, 'password': password},
      ),
      () => _loginWithJson(
        path: '/api/v1/auth/login',
        payload: {'email': username, 'password': password},
      ),
      () => _loginWithToken(username, password),
    ];

    DioException? lastError;

    for (final attempt in attempts) {
      try {
        return await attempt();
      } on DioException catch (e) {
        if (_shouldTryNextEndpoint(e)) {
          lastError = e;
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw const _AuthFailure('Unable to sign in right now. Please try again.');
  }

  Future<_AuthResult> _loginWithJson({
    required String path,
    required Map<String, dynamic> payload,
    bool allowAdminRoleRetry = true,
  }) async {
    final response = await _apiClient.post(path, data: payload);

    return _parseAuthResponse(
      response: response,
      path: path,
      payload: payload,
      allowAdminRoleRetry: allowAdminRoleRetry,
    );
  }

  Future<_AuthResult> _loginWithToken(String username, String password) async {
    final response = await _apiClient.post(
      '/api/v1/auth/token',
      data: {
        'username': username,
        'password': password,
        'grant_type': 'password',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return _parseAuthResponse(
      response: response,
      path: '/api/v1/auth/token',
      payload: const {},
      allowAdminRoleRetry: false,
    );
  }

  Future<_AuthResult> _parseAuthResponse({
    required Response<dynamic> response,
    required String path,
    required Map<String, dynamic> payload,
    required bool allowAdminRoleRetry,
  }) async {
    final data = _normalizeResponseData(response.data);
    final adminRole = _preferredAdminRole(data);
    final currentRole = _extractCurrentRole(data);

    if (allowAdminRoleRetry &&
        path == '/api/v1/auth/login' &&
        !payload.containsKey('role') &&
        adminRole != null &&
        (data['requires_role_selection'] == true ||
            (currentRole != null && !_isAdminRole(currentRole)))) {
      final retriedPayload = <String, dynamic>{...payload, 'role': adminRole};

      final retriedResponse = await _apiClient.post(path, data: retriedPayload);

      return _parseAuthResponse(
        response: retriedResponse,
        path: path,
        payload: retriedPayload,
        allowAdminRoleRetry: false,
      );
    }

    final accessToken = data['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      if (data['requires_role_selection'] == true) {
        final roles = _extractRoles(data);
        if (roles.isNotEmpty) {
          throw _AuthFailure(
            'This account requires role selection before login: ${roles.join(', ')}',
          );
        }
      }

      throw _AuthFailure(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            'Login failed',
      );
    }

    _ensureAdminAccess(data);

    return _AuthResult(
      accessToken: accessToken,
      refreshToken: data['refresh_token']?.toString(),
      user: _extractUser(data),
    );
  }

  Future<void> _persistSession(_AuthResult result) async {
    await _apiClient.storage.write(
      key: 'admin_token',
      value: result.accessToken,
    );

    if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
      await _apiClient.storage.write(
        key: 'admin_refresh_token',
        value: result.refreshToken,
      );
      return;
    }

    await _apiClient.storage.delete(key: 'admin_refresh_token');
  }

  bool _shouldTryNextEndpoint(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 404 ||
        statusCode == 405 ||
        statusCode == 415 ||
        statusCode == 422 ||
        statusCode == 501;
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map && responseData['detail'] != null) {
      return responseData['detail'].toString();
    }

    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }

    return 'Unable to sign in right now. Please try again.';
  }

  Map<String, dynamic> _normalizeResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return const {};
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final user = data['user'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    return null;
  }

  List<String> _extractRoles(Map<String, dynamic> data) {
    final roles = <String>{};

    void addRole(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        roles.add(value.trim());
        return;
      }

      if (value is Map) {
        addRole(value['name']);
        addRole(value['role']);
        addRole(value['user_type']);
        return;
      }

      if (value is Iterable) {
        for (final item in value) {
          addRole(item);
        }
      }
    }

    addRole(data['role']);
    addRole(data['available_roles']);

    final user = data['user'];
    if (user is Map) {
      addRole(user['role']);
      addRole(user['roles']);
      addRole(user['user_type']);
    }

    return roles.toList(growable: false);
  }

  String? _preferredAdminRole(Map<String, dynamic> data) {
    for (final role in _extractRoles(data)) {
      if (_isAdminRole(role)) {
        return role;
      }
    }

    return null;
  }

  String? _extractCurrentRole(Map<String, dynamic> data) {
    final role = data['role'];
    if (role is String && role.trim().isNotEmpty) {
      return role.trim();
    }

    final user = data['user'];
    if (user is Map) {
      final userRole = user['role'];
      if (userRole is String && userRole.trim().isNotEmpty) {
        return userRole.trim();
      }

      if (userRole is Map) {
        final userRoleName = userRole['name'];
        if (userRoleName is String && userRoleName.trim().isNotEmpty) {
          return userRoleName.trim();
        }
      }
    }

    return null;
  }

  void _ensureAdminAccess(Map<String, dynamic> data) {
    final roles = _extractRoles(data);
    if (roles.isEmpty) {
      return;
    }

    if (roles.any(_isAdminRole)) {
      return;
    }

    throw const _AuthFailure('This account does not have admin access.');
  }

  bool _isAdminRole(String role) {
    return _adminRoles.contains(role.trim().toLowerCase());
  }
}

class _AuthResult {
  const _AuthResult({required this.accessToken, this.refreshToken, this.user});

  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
}

class _AuthFailure implements Exception {
  const _AuthFailure(this.message);

  final String message;
}
