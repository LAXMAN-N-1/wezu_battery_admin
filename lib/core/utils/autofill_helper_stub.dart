/// Stub implementation for non-web platforms.
/// Returns empty map — autofill DOM reading is only needed on web.
Map<String, String?> readAutofillValues() {
  return const {'credential': null, 'password': null};
}
