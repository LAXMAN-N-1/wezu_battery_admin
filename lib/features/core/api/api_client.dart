import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();
  String? _memoryAdminToken;
  String? _memoryRefreshToken;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl:
            'https://api1.powerfrill.com',
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
          final token = await readAuthValue('admin_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle unauthorized - logout user or refresh token
            // logout logic could go here
          }
          return handler.next(e);
        },
      ),
    );

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
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
    if (key == 'admin_token') {
      return _memoryAdminToken;
    }
    if (key == 'admin_refresh_token') {
      return _memoryRefreshToken;
    }
    return null;
  }

  void _writeCached(String key, String value) {
    if (key == 'admin_token') {
      _memoryAdminToken = value;
      return;
    }
    if (key == 'admin_refresh_token') {
      _memoryRefreshToken = value;
    }
  }

  void _clearCached(String key) {
    if (key == 'admin_token') {
      _memoryAdminToken = null;
      return;
    }
    if (key == 'admin_refresh_token') {
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
