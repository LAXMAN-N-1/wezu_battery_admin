import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
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

  static const _adminRoles = <String>{
    'admin',
    'super_admin',
    'superadmin',
    'operations_admin',
    'ops_admin',
    'platform_admin',
    'system_admin',
  };

  Future<void> _checkStatus() async {
    final token = await _apiClient.getValidAccessToken(allowRefresh: false);

    if (token != null && token.isNotEmpty) {
      final user = await _resolveSignedInUserContext(null);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
      );
      return;
    }

    // Only attempt refresh when an active refresh token exists. This avoids
    // startup race conditions that can cancel login requests for fresh users.
    if (await _apiClient.hasActiveRefreshToken()) {
      final refreshedToken = await _apiClient.refreshAccessToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        final user = await _resolveSignedInUserContext(null);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          error: null,
        );
        return;
      }
    }

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      error: null,
    );
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

  Future<void> login(String credential, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    _apiClient.unlockSession();

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
      final hydratedUser = await _resolveSignedInUserContext(result.user);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
        user: hydratedUser,
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
            bool isFormEncoded,
          })
        >[
          (
            path: '/api/v1/auth/login',
            payload: {'credential': credential, 'password': password},
            allowAdminRoleRetry: true,
            isFormEncoded: false,
          ),
          (
            path: '/api/v1/auth/admin/login',
            payload: {'username': credential, 'password': password},
            allowAdminRoleRetry: false,
            isFormEncoded: false,
          ),
          (
            path: '/api/v1/auth/admin/login',
            payload: {'email': credential, 'password': password},
            allowAdminRoleRetry: false,
            isFormEncoded: false,
          ),
          (
            path: '/api/v1/auth/login',
            payload: {'credential': credential, 'password': password},
            allowAdminRoleRetry: true,
            isFormEncoded: false,
          ),
          (
            path: '/api/v1/auth/login',
            payload: {'email': credential, 'password': password},
            allowAdminRoleRetry: true,
            isFormEncoded: false,
          ),
          (
            path: '/api/v1/auth/token',
            payload: {
              'username': credential,
              'password': password,
              'grant_type': 'password',
            },
            allowAdminRoleRetry: false,
            isFormEncoded: true,
          ),
        ];

    DioException? lastError;
    var transportFailureAttempts = 0;

    for (final attempt in attempts) {
      try {
        if (attempt.isFormEncoded) {
          return await _loginWithForm(
            path: attempt.path,
            payload: attempt.payload,
          );
        }
        return await _loginWithJson(
          path: attempt.path,
          payload: attempt.payload,
          allowAdminRoleRetry: attempt.allowAdminRoleRetry,
        );
      } on DioException catch (e) {
        _logLoginFailure(e, endpoint: attempt.path);
        if (e.response == null &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout)) {
          transportFailureAttempts += 1;
          if (transportFailureAttempts >= 2) {
            lastError = e;
            break;
          }
        }
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

  Future<_AuthResult> _loginWithForm({
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _apiClient.post(
      path,
      data: payload,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return _parseAuthResponse(
      response: response,
      path: path,
      payload: payload,
      allowAdminRoleRetry: false,
    );
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

  Future<Map<String, dynamic>?> _resolveSignedInUserContext(
    Map<String, dynamic>? loginUser,
  ) async {
    final profile = await _fetchCurrentUserProfile();
    final merged = <String, dynamic>{
      if (loginUser != null) ...loginUser,
      if (profile != null) ...profile,
    };

    if (merged.isEmpty) {
      // Keep admin navigation stable even if profile hydration fails
      // transiently (for example short network interruptions).
      return _fallbackUserContext(loginUser ?? const {'current_role': 'admin'});
    }

    return _fallbackUserContext(merged);
  }

  Future<Map<String, dynamic>?> _fetchCurrentUserProfile() async {
    try {
      final response = await _apiClient.get('/api/v1/users/me');
      final data = _normalizeResponseData(response.data);
      if (data.isEmpty) {
        return null;
      }
      return data;
    } on DioException catch (e) {
      debugPrint('[Auth] current-user fetch skipped: $e');
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _fallbackUserContext(Map<String, dynamic>? user) {
    if (user == null) {
      return null;
    }

    final normalized = <String, dynamic>{...user};
    final role = normalized['current_role'] ?? normalized['role'];
    if (role == null) {
      // /api/v1/auth/admin/login may return minimal user fields; this keeps
      // role-gated navigation visible until /users/me is fetched next.
      normalized['current_role'] = 'admin';
    } else if (normalized['current_role'] == null) {
      if (role is String) {
        normalized['current_role'] = role;
      } else if (role is Map) {
        final roleName = role['name'];
        if (roleName is String && roleName.trim().isNotEmpty) {
          normalized['current_role'] = roleName.trim();
        }
      }
    }

    return normalized;
  }

  bool _shouldTryNextEndpoint(DioException error) {
    if (error.response == null) {
      return true;
    }

    final statusCode = error.response?.statusCode;
    return statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 307 ||
        statusCode == 308 ||
        statusCode == 404 ||
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
    if (error.response == null &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout)) {
      final signal = '${error.message ?? ''} ${error.error ?? ''}'
          .toLowerCase()
          .trim();
      if (kIsWeb && signal.contains('xmlhttprequest')) {
        return 'Browser could not reach the API. '
            'Check API_BASE_URL, backend availability, and CORS.';
      }
    }
    return ApiErrorHandler.getReadableMessage(error);
  }

  void _logLoginFailure(DioException error, {required String endpoint}) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final errorType = error.type;
    final baseUrl = _apiClient.dio.options.baseUrl;
    final message = error.message;
    final rawError = error.error;
    debugPrint(
      '[Auth] login failed baseUrl=$baseUrl endpoint=$endpoint '
      'errorType=$errorType statusCode=$statusCode message=$message '
      'rawError=$rawError responseData=$responseData',
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
    final extracted = <String, dynamic>{};
    final user = data['user'];

    if (user is Map<String, dynamic>) {
      extracted.addAll(user);
    } else if (user is Map) {
      extracted.addAll(Map<String, dynamic>.from(user));
    }

    // Some auth endpoints return role data at top-level with an empty `user`.
    // Preserve this so role-based routing/menu logic remains accurate.
    final topLevelRole = data['current_role'] ?? data['role'];
    if (topLevelRole is String && topLevelRole.trim().isNotEmpty) {
      extracted['current_role'] = topLevelRole.trim();
      extracted.putIfAbsent('role', () => topLevelRole.trim());
    }

    final availableRoles = data['available_roles'];
    if (availableRoles is List && availableRoles.isNotEmpty) {
      extracted.putIfAbsent('roles', () => availableRoles);
    }

    return extracted.isEmpty ? null : extracted;
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
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return _adminRoles.contains(normalized) ||
        normalized == 'administrator' ||
        normalized.endsWith('_admin');
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
