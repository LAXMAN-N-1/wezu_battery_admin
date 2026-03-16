import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();
  void Function()? onUnauthorized;

  ApiClient() {
    String baseUrl = 'https://145.223.19.229.sslip.io:28443';
    String apiPrefix = '/api/v1';

    dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl$apiPrefix/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Host header is automatically handled by browsers/dio; 
          // removing manual override for better compatibility.
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
            final refreshToken = await storage.read(key: 'admin_refresh_token');
            if (refreshToken != null) {
              try {
                // Try to refresh token
                final response = await dio.post(
                  'auth/refresh',
                  data: {'refresh_token': refreshToken},
                  options: Options(headers: {'Authorization': null}), // Clear auth header for refresh
                );

                if (response.statusCode == 200) {
                  final newToken = response.data['access_token'];
                  final newRefreshToken = response.data['refresh_token'];

                  await storage.write(key: 'admin_token', value: newToken);
                  if (newRefreshToken != null) {
                    await storage.write(key: 'admin_refresh_token', value: newRefreshToken);
                  }

                  // Update current request's header and retry
                  e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  
                  // Create a new Options object for the retry
                  final options = Options(
                    method: e.requestOptions.method,
                    headers: e.requestOptions.headers,
                  );

                  final clonedRequest = await dio.request(
                    e.requestOptions.path,
                    options: options,
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );
                  return handler.resolve(clonedRequest);
                }
              } catch (refreshError) {
                debugPrint('ApiClient: Refresh token failed: $refreshError');
                // If refresh fails, fall through to logout
              }
            }

            // Handle unauthorized - logout user
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
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

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await dio.post(path, data: data, options: options);
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
