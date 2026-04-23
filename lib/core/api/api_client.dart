import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;

import 'dio_adapter_stub.dart'
    if (dart.library.io) 'dio_adapter_io.dart'
    if (dart.library.html) 'dio_adapter_web.dart'
    as dio_adapter;
import '../widgets/api_error_handler.dart';
import 'retry_interceptor.dart';
import 'error_formatting_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  static const _fallbackApiBaseUrl = 'https://api3.powerfrill.com';
  static const _skipAuthInterceptorKey = 'skipAuthInterceptor';
  static const _tokenFailureKeywords = {
    'token expired',
    'token has expired',
    'jwt expired',
    'invalid token',
    'invalid_token',
    'invalid jwt',
    'signature has expired',
    'not authenticated',
    'could not validate credentials',
    'token is invalid',
    'token revoked',
  };
  static const _forbiddenTokenFailureKeywords = {
    'token expired',
    'token has expired',
    'invalid token',
    'invalid_token',
    'jwt expired',
    'not authenticated',
    'authentication credentials were not provided',
    'could not validate credentials',
  };
  static const _enforceNoTrailingSlash = bool.fromEnvironment(
    'API_ENFORCE_NO_TRAILING_SLASH',
    defaultValue: true,
  );

  late Dio dio;
  Future<void> Function()? _sessionExpiredCallback;
  bool _sessionExpiredNotified = false;

  /// A global [CancelToken] shared across all in-flight requests.
  CancelToken _globalCancelToken = CancelToken();

  /// Whether the session is currently in a "locked-out" state.
  bool _sessionLocked = false;

  ApiClient._internal() {
    final baseOptions = BaseOptions(
      baseUrl: _resolvedApiBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        if (!kIsWeb) 'Accept-Encoding': 'gzip, deflate',
        if (!kIsWeb) 'Connection': 'keep-alive',
      },
    );

    dio = Dio(baseOptions);
    _configureHttpAdapters();

    dio.interceptors.add(AuthInterceptor(this));
    dio.interceptors.add(RetryInterceptor(dio: dio));
    dio.interceptors.add(ErrorFormattingInterceptor());

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
      defaultValue: '',
    ).trim();
    if (value.isEmpty) {
      if (kIsWeb && kReleaseMode) {
        return '';
      }
      return _fallbackApiBaseUrl;
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  void _configureHttpAdapters() {
    try {
      dio.httpClientAdapter = dio_adapter.createAdapter();
    } catch (_) {
      // Keep Dio defaults
    }
  }

  void registerSessionExpiredCallback(Future<void> Function()? callback) {
    _sessionExpiredCallback = callback;
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

  Future<void> clearSession({bool notifyListeners = false}) async {
    await Supabase.instance.client.auth.signOut();
    if (notifyListeners) {
      await _notifySessionExpired();
    }
  }

  void cancelAllRequests({String reason = 'Session expired'}) {
    if (!_globalCancelToken.isCancelled) {
      _globalCancelToken.cancel(reason);
    }
    _sessionLocked = true;
  }

  void unlockSession() {
    _sessionLocked = false;
    _sessionExpiredNotified = false;
    _globalCancelToken = CancelToken();
  }

  bool get isSessionLocked => _sessionLocked;
  CancelToken get globalCancelToken => _globalCancelToken;

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
        pathLower == '/api/v1/auth/refresh';
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

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      await dio.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken ?? _globalCancelToken);

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      await dio.post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken ?? _globalCancelToken);

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      await dio.put(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken ?? _globalCancelToken);

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      await dio.patch(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken ?? _globalCancelToken);

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async =>
      await dio.delete(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken ?? _globalCancelToken);
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

    if (_apiClient._sessionLocked) {
      handler.reject(
        _apiClient.sessionExpiredException(
          options,
          error: 'Session expired – awaiting re-login',
        ),
      );
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      _apiClient.cancelAllRequests(reason: 'Session expired');
      _apiClient.clearAuthHeader(options.headers);
      await _apiClient.clearSession(notifyListeners: true);
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
      _apiClient.cancelAllRequests(reason: 'Session expired');
      await _apiClient.clearSession(notifyListeners: true);
      handler.reject(
        _apiClient.sessionExpiredException(
          err.requestOptions,
          error: 'Session expired',
        ),
      );
      return;
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
