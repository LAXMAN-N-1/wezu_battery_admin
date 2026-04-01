import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createAdapter() {
  final adapter = BrowserHttpClientAdapter();
  // Bearer-token auth should not send cookies by default.
  adapter.withCredentials = false;
  return adapter;
}

void configureCertBypass(HttpClientAdapter adapter) {
  // Browser does not allow bypassing SSL via code
}
