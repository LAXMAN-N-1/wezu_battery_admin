import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dio_adapter_stub.dart'
    if (dart.library.io) 'dio_adapter_io.dart'
    if (dart.library.html) 'dio_adapter_web.dart'
    as dio_adapter;
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
  static const _tokenInvalidLiterals = {'null', 'undefined', 'nil'};
  static const _tokenFailureKeywords = {
    'token',
    'jwt',
    'bearer',
    'expired',
    'invalid',
    'invalid token',
    'invalid_token',
    'signature',
    'unauthorized',
    'unauthenticated',
    'not authenticated',
    'authentication',
  };
  static const _forbiddenTokenFailureKeywords = {
    'token',
    'jwt',
    'bearer',
    'expired',
    'invalid token',
    'invalid_token',
    'signature',
    'not authenticated',
    'authentication credentials',
  };
  static const _enforceNoTrailingSlash = bool.fromEnvironment(
    'API_ENFORCE_NO_TRAILING_SLASH',
    defaultValue: true,
  );

  late Dio dio;
  late Dio _refreshDio;
  final storage = const FlutterSecureStorage();
  String? _memoryAdminToken;
  String? _memoryRefreshToken;
  Completer<String?>? _refreshCompleter;
  Future<void> Function()? _sessionExpiredCallback;
  bool _sessionExpiredNotified = false;

  ApiClient._internal() {
    final baseOptions = BaseOptions(
      baseUrl: _resolvedApiBaseUrl(),
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    );

    dio = Dio(baseOptions);
    _refreshDio = Dio(baseOptions);
    _configureHttpAdapters();

    dio.interceptors.add(AuthInterceptor(this));

    // Add detailed API logging only in debug mode.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  static String _resolvedApiBaseUrl() {
    final value = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _fallbackApiBaseUrl,
    ).trim();
    if (value.isEmpty) {
      return _fallbackApiBaseUrl;
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  void _configureHttpAdapters() {
    try {
      dio.httpClientAdapter = dio_adapter.createAdapter();
      _refreshDio.httpClientAdapter = dio_adapter.createAdapter();
    } catch (_) {
      // Keep Dio defaults on unsupported adapter platforms.
    }
  }

  void registerSessionExpiredCallback(Future<void> Function()? callback) {
    _sessionExpiredCallback = callback;
  }

  String? sanitizeToken(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (_tokenInvalidLiterals.contains(normalized.toLowerCase())) {
      return null;
    }
    return normalized;
  }

  String normalizeRequestPath(String path) {
    final raw = path.trim();
    if (raw.isEmpty) {
      return raw;
    }

    if (_looksLikeAbsoluteUrl(raw)) {
      final uri = Uri.parse(raw);
      return uri.replace(path: _normalizePathForTransport(uri.path)).toString();
    }

    final queryStart = raw.indexOf('?');
    final pathOnly = queryStart >= 0 ? raw.substring(0, queryStart) : raw;
    final queryPart = queryStart >= 0 ? raw.substring(queryStart) : '';
    return '${_normalizePathForTransport(pathOnly)}$queryPart';
  }

  void ensureStandardRequestHeaders(RequestOptions options) {
    final method = options.method.toUpperCase();

    _removeHeaderIgnoreCase(options.headers, 'Accept');
    options.headers['Accept'] = 'application/json';

    final canHaveBody = const {
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
    }.contains(method);
    final hasBody = options.data != null;
    if (canHaveBody && hasBody) {
      if (!_containsHeaderIgnoreCase(options.headers, 'Content-Type')) {
        options.headers['Content-Type'] = Headers.jsonContentType;
      }
      return;
    }

    _removeHeaderIgnoreCase(options.headers, 'Content-Type');
  }

  void setBearerAuthHeader(Map<String, dynamic> headers, String token) {
    _removeHeaderIgnoreCase(headers, 'Authorization');
    headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthHeader(Map<String, dynamic> headers) {
    _removeHeaderIgnoreCase(headers, 'Authorization');
  }

  bool _looksLikeAbsoluteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String _stripTrailingSlash(String value) {
    if (value.isEmpty || value == '/') {
      return value;
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  String _normalizePathForTransport(String value) {
    final collapsed = value.replaceAll(RegExp(r'/{2,}'), '/');
    if (_enforceNoTrailingSlash) {
      return _stripTrailingSlash(collapsed);
    }
    return collapsed;
  }

  bool _containsHeaderIgnoreCase(Map<String, dynamic> headers, String name) {
    final target = name.toLowerCase();
    return headers.keys.any((key) => key.toString().toLowerCase() == target);
  }

  void _removeHeaderIgnoreCase(Map<String, dynamic> headers, String name) {
    final target = name.toLowerCase();
    final keys = headers.keys
        .where((key) => key.toString().toLowerCase() == target)
        .toList();
    for (final key in keys) {
      headers.remove(key);
    }
  }

  Future<String?> getValidAccessToken({bool allowRefresh = true}) async {
    final token = sanitizeToken(await readAuthValue(accessTokenStorageKey));
    if (token != null && !TokenUtils.isExpired(token)) {
      return token;
    }

    if (!allowRefresh) {
      return null;
    }

    final refreshed = await refreshAccessToken();

    // If refresh fails transiently, keep using the previous token and let the
    // server be the source of truth instead of forcing an immediate logout.
    if (refreshed == null) {
      return token;
    }

    return refreshed;
  }

  Future<String?> refreshAccessToken() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshedToken = await _refreshAccessTokenInternal();
      completer.complete(refreshedToken);
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  Future<void> clearSession({bool notifyListeners = false}) async {
    await deleteAuthValue(accessTokenStorageKey);
    await deleteAuthValue(refreshTokenStorageKey);

    if (notifyListeners) {
      await _notifySessionExpired();
    }
  }

  Future<bool> hasActiveRefreshToken() async {
    final refreshToken = sanitizeToken(
      await readAuthValue(refreshTokenStorageKey),
    );
    return refreshToken != null && !TokenUtils.isExpired(refreshToken);
  }

  Future<Response<dynamic>> retryRequest(
    RequestOptions requestOptions,
    String token,
  ) async {
    final safeToken = sanitizeToken(token);
    if (safeToken == null) {
      throw sessionExpiredException(
        requestOptions,
        error: 'Missing bearer token',
      );
    }

    final headers = Map<String, dynamic>.from(requestOptions.headers);
    setBearerAuthHeader(headers, safeToken);

    final extra = Map<String, dynamic>.from(requestOptions.extra);
    extra[_skipAuthInterceptorKey] = true;

    final options = Options(
      method: requestOptions.method,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      extra: extra,
      followRedirects: requestOptions.followRedirects,
      maxRedirects: requestOptions.maxRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      listFormat: requestOptions.listFormat,
      requestEncoder: requestOptions.requestEncoder,
      responseDecoder: requestOptions.responseDecoder,
      validateStatus: requestOptions.validateStatus,
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

  bool shouldSkipAuthInterceptor(RequestOptions options) {
    if (options.extra[_skipAuthInterceptorKey] == true) {
      return true;
    }

    final normalizedPath = normalizeRequestPath(options.path);
    final pathLower = _stripTrailingSlash(
      _looksLikeAbsoluteUrl(normalizedPath)
          ? (Uri.tryParse(normalizedPath)?.path ?? normalizedPath)
          : normalizedPath.split('?').first,
    ).toLowerCase();

    return pathLower == '/api/v1/auth/login' ||
        pathLower == '/api/v1/auth/admin/login' ||
        pathLower == '/api/v1/auth/refresh' ||
        pathLower == '/api/v1/auth/token/refresh' ||
        pathLower == '/api/v1/auth/refresh-token';
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

  bool isLikelyAuthFailure(DioException error, {bool includeForbidden = true}) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return true;
    }

    if (statusCode == 400) {
      return _responseMentionsTokenFailure(
        error.response?.data,
        keywords: _tokenFailureKeywords,
      );
    }

    if (includeForbidden && statusCode == 403) {
      return _responseMentionsTokenFailure(
        error.response?.data,
        keywords: _forbiddenTokenFailureKeywords,
      );
    }
    return false;
  }

  bool _responseMentionsTokenFailure(
    dynamic data, {
    Set<String> keywords = _tokenFailureKeywords,
  }) {
    if (data == null) {
      return false;
    }
    final text = data.toString().toLowerCase();
    return keywords.any(text.contains);
  }

  Future<String?> _refreshAccessTokenInternal() async {
    final refreshToken = sanitizeToken(
      await readAuthValue(refreshTokenStorageKey),
    );
    if (refreshToken == null || TokenUtils.isExpired(refreshToken)) {
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
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $refreshToken',
            },
            extra: const {_skipAuthInterceptorKey: true},
          ),
        );

        final data = _normalizeResponseData(response.data);
        final newAccessToken = sanitizeToken(_extractAccessToken(data));
        if (newAccessToken == null) {
          continue;
        }

        final newRefreshToken =
            sanitizeToken(_extractRefreshToken(data)) ?? refreshToken;

        await writeAuthValue(accessTokenStorageKey, newAccessToken);
        await writeAuthValue(refreshTokenStorageKey, newRefreshToken);
        _sessionExpiredNotified = false;
        return newAccessToken;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final shouldContinue =
            statusCode == 404 || statusCode == 405 || statusCode == 415;

        if (shouldContinue) {
          continue;
        }

        // 422 can be endpoint contract mismatch or invalid refresh token payload.
        if (statusCode == 422) {
          if (_responseMentionsTokenFailure(e.response?.data)) {
            await clearSession(notifyListeners: true);
            return null;
          }
          continue;
        }

        // Explicit auth failures mean session is invalid and must be cleared.
        if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
          await clearSession(notifyListeners: true);
          return null;
        }

        // Do not clear session on transient server/network issues.
        if (statusCode != null && statusCode >= 500) {
          debugPrint('[ApiClient] token refresh failed: $e');
          return null;
        }

        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          debugPrint('[ApiClient] token refresh transient failure: $e');
          return null;
        }

        debugPrint('[ApiClient] token refresh failed: $e');
        return null;
      }
    }
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
    final direct = sanitizeToken(
      data['access_token']?.toString() ?? data['token']?.toString(),
    );
    if (direct != null) {
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
    final direct = sanitizeToken(data['refresh_token']?.toString());
    if (direct != null) {
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
    final cached = sanitizeToken(_readCached(key));
    if (cached != null) {
      return cached;
    }

    try {
      final secureValue = await storage.read(key: key);
      final sanitized = sanitizeToken(secureValue);
      if (sanitized != null) {
        _writeCached(key, sanitized);
        return sanitized;
      }
    } catch (e) {
      debugPrint('[ApiClient] secure read failed for $key: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final fallbackValue = prefs.getString(key);
      final sanitized = sanitizeToken(fallbackValue);
      if (sanitized != null) {
        _writeCached(key, sanitized);
        return sanitized;
      }
    } catch (e) {
      debugPrint('[ApiClient] shared prefs read failed for $key: $e');
    }

    return null;
  }

  Future<void> writeAuthValue(String key, String value) async {
    final sanitized = sanitizeToken(value);
    if (sanitized == null) {
      await deleteAuthValue(key);
      return;
    }

    _writeCached(key, sanitized);

    try {
      await storage.write(key: key, value: sanitized);
    } catch (e) {
      debugPrint('[ApiClient] secure write failed for $key: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, sanitized);
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
    options.path = _apiClient.normalizeRequestPath(options.path);
    _apiClient.ensureStandardRequestHeaders(options);

    if (_apiClient.shouldSkipAuthInterceptor(options)) {
      handler.next(options);
      return;
    }

    final token = _apiClient.sanitizeToken(
      await _apiClient.getValidAccessToken(),
    );
    if (token == null) {
      _apiClient.clearAuthHeader(options.headers);
      handler.reject(
        _apiClient.sessionExpiredException(options, error: 'Session expired'),
      );
      return;
    }

    _apiClient.setBearerAuthHeader(options.headers, token);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_apiClient.shouldSkipAuthInterceptor(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final statusCode = err.response?.statusCode;
    if (_apiClient.isLikelyAuthFailure(err)) {
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

      // If refresh token is still present, treat this as a transient auth-path
      // failure (for example CORS-masked refresh/network issues) and avoid
      // hard logout loops.
      if (statusCode == 401 && await _apiClient.hasActiveRefreshToken()) {
        ApiErrorHandler.showGlobalError(err);
        handler.next(err);
        return;
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

    // Never invalidate session on network/CORS-like transport failures.

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
