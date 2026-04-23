import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/api/api_client.dart';
import '../../../core/widgets/api_error_handler.dart';

final authProvider = StateNotifierProvider.autoDispose<AuthNotifier, AuthState>(
  (ref) {
    return AuthNotifier(ref.read(apiClientProvider));
  },
);

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

    _authStateSubscription = supabase
        .Supabase
        .instance
        .client
        .auth
        .onAuthStateChange
        .listen((data) {
          final supabase.AuthChangeEvent event = data.event;
          if (event == supabase.AuthChangeEvent.signedOut) {
            _onSessionExpired();
          } else if (event == supabase.AuthChangeEvent.signedIn ||
              event == supabase.AuthChangeEvent.tokenRefreshed) {
            _checkStatus();
          }
        });

    _checkStatus();
  }

  final ApiClient _apiClient;
  late final StreamSubscription<supabase.AuthState> _authStateSubscription;

  static const _adminRoles = <String>{
    'admin',
    'super_admin',
    'superadmin',
    'operations_admin',
    'security_admin',
    'finance_admin',
    'logistics_manager',
  };

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final session = supabase.Supabase.instance.client.auth.currentSession;

    if (session == null) {
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
      if (_apiClient.isLikelyAuthFailure(e)) {
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
    return supabase.Supabase.instance.client.auth.currentSession?.accessToken;
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
    final rawPassword = password;

    if (normalizedCredential.isEmpty || rawPassword.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Enter your login credential and password.',
        user: null,
      );
      return;
    }

    try {
      _apiClient.unlockSession();

      final response = await supabase.Supabase.instance.client.auth
          .signInWithPassword(
            email: normalizedCredential,
            password: rawPassword,
          );

      if (response.session == null) {
        throw const _AuthFailure('Login failed.');
      }

      Map<String, dynamic>? currentUser;
      try {
        currentUser = await _fetchCurrentAdminUser();
      } on _AuthFailure {
        await _apiClient.clearSession(notifyListeners: false);
        rethrow;
      } on DioException catch (e) {
        if (_apiClient.isLikelyAuthFailure(e)) {
          await _apiClient.clearSession(notifyListeners: false);
          rethrow;
        }
        debugPrint('[Auth] /users/me check skipped after login: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
        user: currentUser,
      );
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.message,
        user: null,
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
        error: ApiErrorHandler.getReadableMessage(e),
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

  Future<Map<String, dynamic>> _fetchCurrentAdminUser() async {
    final response = await _apiClient.get('/api/v1/auth/me');
    final data = _normalizeResponseData(response.data);
    _ensureCurrentSessionHasAdminAccess(data);
    return data;
  }

  Map<String, dynamic> _normalizeResponseData(dynamic data) {
    final map = data is Map<String, dynamic>
        ? Map<String, dynamic>.from(data)
        : data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    final nestedUser = _extractUser(map);
    if (nestedUser == null) return map;

    final normalized = <String, dynamic>{
      ...nestedUser,
      'user': nestedUser,
      if (map['roles'] != null) 'roles': map['roles'],
      if (map['permissions'] != null) 'permissions': map['permissions'],
      if (map['identity_provider'] != null)
        'identity_provider': map['identity_provider'],
      if (map['identity_subject'] != null)
        'identity_subject': map['identity_subject'],
    };

    final fullName = normalized['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) {
      normalized.putIfAbsent('name', () => fullName);
    }

    final roles = _extractRoles(normalized);
    if (roles.isNotEmpty) {
      normalized.putIfAbsent('current_role', () => roles.first);
      normalized.putIfAbsent('role', () => roles.first);
      normalized.putIfAbsent('available_roles', () => roles);
    }

    return normalized;
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

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic>) return user;
    if (user is Map) return Map<String, dynamic>.from(user);
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
    addRole(data['roles']);
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

  String? _extractCurrentRole(Map<String, dynamic> data) {
    final currentRole = data['current_role'];
    if (currentRole is String && currentRole.trim().isNotEmpty) {
      return currentRole.trim();
    }

    final role = data['role'];
    if (role is String && role.trim().isNotEmpty) return role.trim();

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

  bool _isAdminRole(String role) {
    return _adminRoles.contains(role.trim().toLowerCase());
  }
}

class _AuthFailure implements Exception {
  const _AuthFailure(this.message);
  final String message;
}
