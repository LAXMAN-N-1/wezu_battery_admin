import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio interceptor that automatically retries failed **GET** requests with
/// exponential back-off.
///
/// Only idempotent reads (GET / HEAD) are retried.  Mutating requests are
/// never retried to avoid unintended side-effects.
///
/// Retries happen for:
///   • Network errors (socket, DNS, timeout)
///   • Server errors (HTTP 500, 502, 503, 504)
///
/// Configuration defaults: 3 retries with 1 s → 2 s → 4 s delays.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  static const _retryableStatusCodes = {500, 502, 503, 504};

  bool _isIdempotent(RequestOptions options) {
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'HEAD';
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    // Only retry idempotent requests
    if (!_isIdempotent(options)) {
      return handler.next(err);
    }

    // Determine if retryable
    final isRetryable = _isNetworkError(err) || _isServerError(err);
    if (!isRetryable) {
      return handler.next(err);
    }

    // Track retry count
    final attempt = (options.extra['_retryCount'] as int?) ?? 0;
    if (attempt >= maxRetries) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    final delay = baseDelay * pow(2, attempt);

    if (kDebugMode) {
      debugPrint(
        '[RetryInterceptor] Retry $nextAttempt/$maxRetries for '
        '${options.method} ${options.path} after ${delay.inMilliseconds}ms',
      );
    }

    await Future.delayed(delay);

    // Clone the request with updated retry count
    options.extra['_retryCount'] = nextAttempt;

    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.reject(e);
    }
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown;
  }

  bool _isServerError(DioException err) {
    final statusCode = err.response?.statusCode;
    return statusCode != null && _retryableStatusCodes.contains(statusCode);
  }
}
