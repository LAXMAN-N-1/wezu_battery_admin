import 'dart:html' as html;

/// Reads autofill values from DOM <input> elements on Flutter web.
///
/// Flutter web creates hidden <input> elements for each TextFormField.
/// When a password manager fills them, the DOM values update but
/// Flutter's TextEditingController never syncs. This reads the DOM directly.
///
/// Returns a map with keys 'credential' and 'password' (may be null).
Map<String, String?> readAutofillValues() {
  String? credential;
  String? password;

  try {
    final inputs = html.document.querySelectorAll('input');
    for (var i = 0; i < inputs.length; i++) {
      final el = inputs[i];
      if (el is! html.InputElement) continue;

      final type = (el.type ?? '').toLowerCase();
      final value = el.value ?? '';
      if (value.isEmpty) continue;

      if (type == 'password') {
        password = value;
      } else if (type == 'text' || type == 'email' || type == '') {
        // Take the last non-empty text/email input as credential
        // (Flutter may create internal inputs; the visible one comes later)
        credential = value;
      }
    }
  } catch (_) {
    // Swallow — caller has fallback logic.
  }

  return {'credential': credential, 'password': password};
}
