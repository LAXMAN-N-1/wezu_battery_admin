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
  static const disableRetryKey = 'disableRetry';
  static const retryOnReceiveTimeoutKey = 'retryOnReceiveTimeout';
  static const retryOnSendTimeoutKey = 'retryOnSendTimeout';
  static const maxRetriesKey = 'maxRetries';

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  static const _retryableStatusCodes = {408, 429, 502, 503, 504};

  bool _isIdempotent(RequestOptions options) {
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'HEAD';
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    if (options.extra[disableRetryKey] == true ||
        err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    // Only retry idempotent requests
    if (!_isIdempotent(options)) {
      return handler.next(err);
    }

    // Determine if retryable
    final isRetryable = _isNetworkError(err, options) || _isServerError(err);
    if (!isRetryable) {
      return handler.next(err);
    }

    // Track retry count
    final attempt = (options.extra['_retryCount'] as int?) ?? 0;
    final allowedRetries = (options.extra[maxRetriesKey] as int?) ?? maxRetries;
    if (attempt >= allowedRetries) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    final backoffDelay = baseDelay * pow(2, attempt);
    final delay = _retryDelay(err.response) ?? backoffDelay;

    if (kDebugMode) {
      debugPrint(
        '[RetryInterceptor] Retry $nextAttempt/$allowedRetries for '
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

  bool _isNetworkError(DioException err, RequestOptions options) {
    return err.type == DioExceptionType.connectionTimeout ||
        (err.type == DioExceptionType.sendTimeout &&
            options.extra[retryOnSendTimeoutKey] == true) ||
        (err.type == DioExceptionType.receiveTimeout &&
            options.extra[retryOnReceiveTimeoutKey] == true) ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown;
  }

  bool _isServerError(DioException err) {
    final statusCode = err.response?.statusCode;
    return statusCode != null && _retryableStatusCodes.contains(statusCode);
  }

  Duration? _retryDelay(Response<dynamic>? response) {
    final rawRetryAfter = response?.headers.value('retry-after');
    if (rawRetryAfter == null) {
      return null;
    }

    final seconds = int.tryParse(rawRetryAfter.trim());
    if (seconds != null && seconds >= 0) {
      return Duration(seconds: seconds);
    }

    final retryAt = DateTime.tryParse(rawRetryAfter);
    if (retryAt == null) {
      return null;
    }

    final delay = retryAt.difference(DateTime.now().toUtc());
    return delay.isNegative ? Duration.zero : delay;
  }
}
