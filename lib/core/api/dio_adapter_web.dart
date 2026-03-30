import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

void configureCertBypass(HttpClientAdapter adapter) {
  // Browser does not allow bypassing SSL via code
}
