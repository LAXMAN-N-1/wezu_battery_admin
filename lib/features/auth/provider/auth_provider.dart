import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../../core/widgets/api_error_handler.dart';

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
  AuthNotifier(this._apiClient) : super(AuthState(isLoading: true)) {
    _apiClient.registerSessionExpiredCallback(_onSessionExpired);
    _checkStatus();
  }

  final ApiClient _apiClient;

  static const _adminRoles = <String>{'admin', 'super_admin', 'superadmin'};

  bool _isSessionInvalidError(DioException error) {
    return _apiClient.isLikelyAuthFailure(error);
  }

  Future<void> _checkStatus() async {
    final token = await _apiClient.getValidAccessToken();

    if (token == null || token.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: null,
        user: null,
      );
      return;
    }

    // Optimistic auth when token exists. We only drop session on explicit
    // token/auth failures; transient backend/network failures should not log
    // out an otherwise valid user.
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      error: null,
    );

    try {
      final currentUser = await _fetchCurrentAdminUser();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
        user: currentUser,
      );
    } on _AuthFailure {
      await _apiClient.clearSession(notifyListeners: false);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: null,
        user: null,
      );
    } on DioException catch (e) {
      if (_isSessionInvalidError(e)) {
        await _apiClient.clearSession(notifyListeners: false);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          error: null,
          user: null,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    }
  }

  Future<void> _onSessionExpired() async {
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      error: 'Your session has expired. Please log in again.',
    );
  }

  Future<String?> getValidAccessToken() async {
    return _apiClient.getValidAccessToken();
  }

  Future<String?> refreshAccessToken() async {
    return _apiClient.refreshAccessToken();
  }

  Future<void> clearSessionAndRedirect() async {
    await _apiClient.clearSession(notifyListeners: false);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      error: 'Your session has expired. Please log in again.',
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> login(String credential, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final normalizedCredential = credential.trim();
    final normalizedPassword = password.trim();

    if (normalizedCredential.isEmpty || normalizedPassword.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Enter your login credential and password.',
        user: null,
      );
      return;
    }

    try {
      final result = await _authenticate(
        normalizedCredential,
        normalizedPassword,
      );
      await _persistSession(result);

      Map<String, dynamic>? currentUser = result.user;
      try {
        currentUser = await _fetchCurrentAdminUser();
      } on _AuthFailure {
        await _apiClient.clearSession(notifyListeners: false);
        rethrow;
      } on DioException catch (e) {
        if (_isSessionInvalidError(e)) {
          await _apiClient.clearSession(notifyListeners: false);
          rethrow;
        }

        // Continue login flow with parsed user payload if current-user probe
        // fails due transient connectivity/server issues.
        debugPrint('[Auth] /users/me check skipped after login: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
        user: currentUser,
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
    await _apiClient.clearSession(notifyListeners: false);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      error: null,
      user: null,
    );
  }

  Future<_AuthResult> _authenticate(String credential, String password) async {
    final attempts =
        <
          ({
            String path,
            Map<String, dynamic> payload,
            bool allowAdminRoleRetry,
          })
        >[
          (
            path: '/api/v1/auth/admin/login',
            payload: {'username': credential, 'password': password},
            allowAdminRoleRetry: false,
          ),
          (
            path: '/api/v1/auth/admin/login',
            payload: {'email': credential, 'password': password},
            allowAdminRoleRetry: false,
          ),
          (
            path: '/api/v1/auth/admin/login',
            payload: {'credential': credential, 'password': password},
            allowAdminRoleRetry: false,
          ),
          (
            path: '/api/v1/auth/login',
            payload: {'credential': credential, 'password': password},
            allowAdminRoleRetry: true,
          ),
          (
            path: '/api/v1/auth/login',
            payload: {'username': credential, 'password': password},
            allowAdminRoleRetry: true,
          ),
          (
            path: '/api/v1/auth/login',
            payload: {'email': credential, 'password': password},
            allowAdminRoleRetry: true,
          ),
        ];

    DioException? lastError;

    for (final attempt in attempts) {
      try {
        return await _loginWithJson(
          path: attempt.path,
          payload: attempt.payload,
          allowAdminRoleRetry: attempt.allowAdminRoleRetry,
        );
      } on DioException catch (e) {
        _logLoginFailure(e, endpoint: attempt.path);
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
    final response = await _apiClient.post(
      path,
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );

    return _parseAuthResponse(
      response: response,
      path: path,
      payload: payload,
      allowAdminRoleRetry: allowAdminRoleRetry,
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

      final retriedResponse = await _apiClient.post(
        path,
        data: retriedPayload,
        options: Options(contentType: Headers.jsonContentType),
      );

      return _parseAuthResponse(
        response: retriedResponse,
        path: path,
        payload: retriedPayload,
        allowAdminRoleRetry: false,
      );
    }

    final accessToken = data['access_token']?.toString();
    final refreshToken = data['refresh_token']?.toString();
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
            data['error']?.toString() ??
            'Login failed',
      );
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const _AuthFailure('Login failed: refresh token missing.');
    }

    _ensureAdminAccess(data);

    return _AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: _extractUser(data),
    );
  }

  Future<void> _persistSession(_AuthResult result) async {
    await _apiClient.writeAuthValue(
      ApiClient.accessTokenStorageKey,
      result.accessToken,
    );
    await _apiClient.writeAuthValue(
      ApiClient.refreshTokenStorageKey,
      result.refreshToken,
    );
  }

  bool _shouldTryNextEndpoint(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 404 ||
        statusCode == 405 ||
        statusCode == 415 ||
        statusCode == 422 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        statusCode == 501;
  }

  String _extractErrorMessage(DioException error) {
    return ApiErrorHandler.getReadableMessage(error);
  }

  void _logLoginFailure(DioException error, {required String endpoint}) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    debugPrint(
      '[Auth] login failed endpoint=$endpoint statusCode=$statusCode responseData=$responseData',
    );
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

  Future<Map<String, dynamic>> _fetchCurrentAdminUser() async {
    final response = await _apiClient.get('/api/v1/users/me');
    final data = _normalizeResponseData(response.data);
    _ensureCurrentSessionHasAdminAccess(data);
    return data;
  }

  void _ensureCurrentSessionHasAdminAccess(Map<String, dynamic> data) {
    final currentRole = _extractCurrentRole(data);
    final roles = _extractRoles(data);
    final userType = _extractUserType(data);

    if (_isSuperuser(data) ||
        (currentRole != null && _isAdminRole(currentRole)) ||
        (userType != null && _isAdminRole(userType)) ||
        roles.any(_isAdminRole)) {
      return;
    }

    throw const _AuthFailure('This account does not have admin access.');
  }

  String? _extractUserType(Map<String, dynamic> data) {
    final userType = data['user_type'];
    if (userType is String && userType.trim().isNotEmpty) {
      return userType.trim();
    }

    final user = _extractUser(data);
    final nestedUserType = user?['user_type'];
    if (nestedUserType is String && nestedUserType.trim().isNotEmpty) {
      return nestedUserType.trim();
    }

    return null;
  }

  bool _isSuperuser(Map<String, dynamic> data) {
    if (data['is_superuser'] == true || data['isSuperuser'] == true) {
      return true;
    }

    final user = _extractUser(data);
    return user?['is_superuser'] == true || user?['isSuperuser'] == true;
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
        addRole(value['current_role']);
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
    addRole(data['current_role']);
    addRole(data['available_roles']);

    final user = _extractUser(data);
    if (user != null) {
      addRole(user['role']);
      addRole(user['roles']);
      addRole(user['current_role']);
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
    final currentRole = data['current_role'];
    if (currentRole is String && currentRole.trim().isNotEmpty) {
      return currentRole.trim();
    }

    final role = data['role'];
    if (role is String && role.trim().isNotEmpty) {
      return role.trim();
    }

    final user = _extractUser(data);
    if (user != null) {
      final userCurrentRole = user['current_role'];
      if (userCurrentRole is String && userCurrentRole.trim().isNotEmpty) {
        return userCurrentRole.trim();
      }

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
  const _AuthResult({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic>? user;
}

class _AuthFailure implements Exception {
  const _AuthFailure(this.message);

  final String message;
}
