import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

HttpClientAdapter createAdapter() {
  return IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient()
        ..idleTimeout = const Duration(seconds: 15)
        ..maxConnectionsPerHost = 6
        ..autoUncompress = true;
      return client;
    },
  );
}

void configureCertBypass(HttpClientAdapter adapter) {
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = HttpClient()
        ..idleTimeout = const Duration(seconds: 15)
        ..maxConnectionsPerHost = 6
        ..autoUncompress = true;
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }
}
