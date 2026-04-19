import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../utils/token_utils.dart';
import '../widgets/api_error_handler.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  static const _fallbackApiBaseUrl = 'https://api1.powerfrill.com';
  static const accessTokenStorageKey = 'admin_token';
  static const refreshTokenStorageKey = 'admin_refresh_token';
  static const _skipAuthInterceptorKey = 'skipAuthInterceptor';

  late Dio dio;
  late Dio _refreshDio;
  final storage = const FlutterSecureStorage();
  String? _memoryAdminToken;
  String? _memoryRefreshToken;
  Completer<String?>? _refreshCompleter;
  Future<void> Function()? _sessionExpiredCallback;
  bool _sessionExpiredNotified = false;

  // Dynamic base URL from .env (falls back to localhost for dev)
  static String get baseUrl =>
      dotenv.env['API_ROOT_URL'] ?? 'http://127.0.0.1:8000';

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'admin_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Attempt token refresh before giving up
            final refreshToken = await storage.read(key: 'admin_refresh_token');
            if (refreshToken != null) {
              try {
                final response = await Dio().post(
                  '$baseUrl/api/v1/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                final newToken = response.data['access_token'];
                final newRefresh = response.data['refresh_token'];

                await storage.write(key: 'admin_token', value: newToken);
                if (newRefresh != null) {
                  await storage.write(key: 'admin_refresh_token', value: newRefresh);
                }

                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (_) {
                // Refresh failed — clear tokens
                await storage.delete(key: 'admin_token');
                await storage.delete(key: 'admin_refresh_token');
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response<dynamic>> retryRequest(RequestOptions requestOptions, String token) {
    requestOptions.headers['Authorization'] = 'Bearer $token';
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      options: options,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }

  Future<void> clearSession({bool notifyListeners = false}) async {
    await deleteAuthValue(accessTokenStorageKey);
    await deleteAuthValue(refreshTokenStorageKey);
    if (notifyListeners) {
      await _notifySessionExpired();
    }
  }

  Future<String?> getValidAccessToken() async {
    final token = await readAuthValue(accessTokenStorageKey);
    if (token == null || token.isEmpty) return null;
    
    if (TokenUtils.isExpired(token)) {
      return await refreshAccessToken();
    }
    return token;
  }

  void registerSessionExpiredCallback(Future<void> Function() callback) {
    _sessionExpiredCallback = callback;
  }

  Future<String?> refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final newToken = await _refreshAccessTokenInternal();
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  bool shouldSkipAuthInterceptor(RequestOptions options) {
    if (options.extra[_skipAuthInterceptorKey] == true) {
      return true;
    }

    final path = options.path.toLowerCase();
    return path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/admin/login') ||
        path.contains('/api/v1/auth/refresh') ||
        path.contains('/api/v1/auth/token/refresh') ||
        path.contains('/api/v1/auth/refresh-token');
  }

  DioException sessionExpiredException(
    RequestOptions options, {
    Object? error,
  }) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.cancel,
      error: error ?? 'Session expired',
    );
  }

  Future<String?> _refreshAccessTokenInternal() async {
    final refreshToken = await readAuthValue(refreshTokenStorageKey);
    if (TokenUtils.isExpired(refreshToken)) {
      await clearSession(notifyListeners: true);
      return null;
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession(notifyListeners: true);
      return null;
    }

    final attempts = <({String path, Map<String, dynamic> payload})>[
      (path: '/api/v1/auth/refresh', payload: {'refresh_token': refreshToken}),
      (
        path: '/api/v1/auth/token/refresh',
        payload: {'refresh_token': refreshToken},
      ),
      (
        path: '/api/v1/auth/admin/refresh',
        payload: {'refresh_token': refreshToken},
      ),
      (
        path: '/api/v1/auth/refresh-token',
        payload: {'refresh_token': refreshToken},
      ),
      (path: '/api/v1/auth/refresh', payload: {'refresh': refreshToken}),
    ];

    for (final attempt in attempts) {
      try {
        final response = await _refreshDio.post<dynamic>(
          attempt.path,
          data: attempt.payload,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {'Authorization': 'Bearer $refreshToken'},
            extra: const {_skipAuthInterceptorKey: true},
          ),
        );

        final data = _normalizeResponseData(response.data);
        final newAccessToken = _extractAccessToken(data);
        if (newAccessToken == null || newAccessToken.isEmpty) {
          continue;
        }

        final newRefreshToken = _extractRefreshToken(data) ?? refreshToken;

        await writeAuthValue(accessTokenStorageKey, newAccessToken);
        await writeAuthValue(refreshTokenStorageKey, newRefreshToken);
        _sessionExpiredNotified = false;
        return newAccessToken;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final shouldContinue =
            statusCode == 404 ||
            statusCode == 405 ||
            statusCode == 415 ||
            statusCode == 422;

        if (!shouldContinue) {
          debugPrint('[ApiClient] token refresh failed: $e');
          break;
        }
      }
    }

    await clearSession(notifyListeners: true);
    return null;
  }

  Future<void> _notifySessionExpired() async {
    if (_sessionExpiredNotified) {
      return;
    }
    _sessionExpiredNotified = true;

    final callback = _sessionExpiredCallback;
    if (callback != null) {
      await callback();
    }
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

  String? _extractAccessToken(Map<String, dynamic> data) {
    final direct =
        data['access_token']?.toString() ?? data['token']?.toString();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return _extractAccessToken(nested);
    }
    if (nested is Map) {
      return _extractAccessToken(Map<String, dynamic>.from(nested));
    }
    return null;
  }

  String? _extractRefreshToken(Map<String, dynamic> data) {
    final direct = data['refresh_token']?.toString();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return _extractRefreshToken(nested);
    }
    if (nested is Map) {
      return _extractRefreshToken(Map<String, dynamic>.from(nested));
    }
    return null;
  }

  Future<String?> readAuthValue(String key) async {
    final cached = _readCached(key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final secureValue = await storage.read(key: key);
      if (secureValue != null && secureValue.isNotEmpty) {
        _writeCached(key, secureValue);
        return secureValue;
      }
    } catch (e) {
      debugPrint('[ApiClient] secure read failed for $key: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final fallbackValue = prefs.getString(key);
      if (fallbackValue != null && fallbackValue.isNotEmpty) {
        _writeCached(key, fallbackValue);
        return fallbackValue;
      }
    } catch (e) {
      debugPrint('[ApiClient] shared prefs read failed for $key: $e');
    }

    return null;
  }

  Future<void> writeAuthValue(String key, String value) async {
    _writeCached(key, value);

    try {
      await storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[ApiClient] secure write failed for $key: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('[ApiClient] shared prefs write failed for $key: $e');
    }
  }

  Future<void> deleteAuthValue(String key) async {
    _clearCached(key);

    try {
      await storage.delete(key: key);
    } catch (e) {
      debugPrint('[ApiClient] secure delete failed for $key: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[ApiClient] shared prefs delete failed for $key: $e');
    }
  }

  String? _readCached(String key) {
    if (key == accessTokenStorageKey) {
      return _memoryAdminToken;
    }
    if (key == refreshTokenStorageKey) {
      return _memoryRefreshToken;
    }
    return null;
  }

  void _writeCached(String key, String value) {
    if (key == accessTokenStorageKey) {
      _memoryAdminToken = value;
      _sessionExpiredNotified = false;
      return;
    }
    if (key == refreshTokenStorageKey) {
      _memoryRefreshToken = value;
    }
  }

  void _clearCached(String key) {
    if (key == accessTokenStorageKey) {
      _memoryAdminToken = null;
      return;
    }
    if (key == refreshTokenStorageKey) {
      _memoryRefreshToken = null;
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._apiClient);

  final ApiClient _apiClient;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_apiClient.shouldSkipAuthInterceptor(options)) {
      handler.next(options);
      return;
    }

    final token = await _apiClient.getValidAccessToken();
    if (token == null) {
      handler.reject(
        _apiClient.sessionExpiredException(options, error: 'Session expired'),
      );
      return;
    }

    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_apiClient.shouldSkipAuthInterceptor(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      try {
        final newToken = await _apiClient.refreshAccessToken();
        if (newToken != null) {
          final response = await _apiClient.retryRequest(
            err.requestOptions,
            newToken,
          );
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Fall through and invalidate session.
      }

      await _apiClient.clearSession(notifyListeners: true);
      handler.reject(
        _apiClient.sessionExpiredException(
          err.requestOptions,
          error: 'Session expired',
        ),
      );
      return;
    }

    if (err.type == DioExceptionType.connectionError && err.response == null) {
      final token = await _apiClient.readAuthValue(
        ApiClient.accessTokenStorageKey,
      );
      if (TokenUtils.isExpired(token)) {
        await _apiClient.clearSession(notifyListeners: true);
        handler.reject(
          _apiClient.sessionExpiredException(
            err.requestOptions,
            error: 'Session expired',
          ),
        );
        return;
      }
    }

    final isServerError = statusCode != null && statusCode >= 500;
    final isConnectionIssue =
        err.response == null &&
        (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout);

    if (isServerError || isConnectionIssue) {
      ApiErrorHandler.showGlobalError(err);
    }

    handler.next(err);
  }
}
