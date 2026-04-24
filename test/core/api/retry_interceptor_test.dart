import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_admin/core/api/retry_interceptor.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._fetch);

  final Future<ResponseBody> Function(RequestOptions options) _fetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _fetch(options);
  }
}

void main() {
  test('does not retry receive timeouts by default', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    var attempts = 0;
    dio.httpClientAdapter = _FakeAdapter((options) async {
      attempts++;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    });

    dio.interceptors.add(
      RetryInterceptor(dio: dio, maxRetries: 3, baseDelay: Duration.zero),
    );

    await expectLater(
      dio.get('/orders'),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );
    expect(attempts, 1);
  });

  test('retries connection errors by default', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    var attempts = 0;
    dio.httpClientAdapter = _FakeAdapter((options) async {
      attempts++;
      if (attempts == 1) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }

      return ResponseBody.fromString(
        jsonEncode(const {'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    dio.interceptors.add(
      RetryInterceptor(dio: dio, maxRetries: 3, baseDelay: Duration.zero),
    );

    final response = await dio.get('/orders');

    expect(response.statusCode, 200);
    expect(attempts, 2);
  });

  test('can opt into retrying receive timeouts for a request', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    var attempts = 0;
    dio.httpClientAdapter = _FakeAdapter((options) async {
      attempts++;
      if (attempts == 1) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      }

      return ResponseBody.fromString(
        jsonEncode(const {'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    dio.interceptors.add(
      RetryInterceptor(dio: dio, maxRetries: 3, baseDelay: Duration.zero),
    );

    final response = await dio.get(
      '/orders',
      options: Options(
        extra: const {RetryInterceptor.retryOnReceiveTimeoutKey: true},
      ),
    );

    expect(response.statusCode, 200);
    expect(attempts, 2);
  });
}
