import 'dart:convert';

class TokenUtils {
  /// Decodes a JWT and returns the payload as a map.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if token is expired or invalid.
  static bool isExpired(String? token) {
    if (token == null || token.isEmpty) {
      return true;
    }

    final payload = decodePayload(token);
    if (payload == null) {
      return true;
    }

    final exp = payload['exp'];
    if (exp == null) {
      return true;
    }

    final expiryEpochSeconds = _asEpochSeconds(exp);
    if (expiryEpochSeconds == null) {
      return true;
    }

    // Add 30-second buffer to account for clock skew.
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      expiryEpochSeconds * 1000,
    ).subtract(const Duration(seconds: 30));

    return DateTime.now().isAfter(expiryTime);
  }

  /// Returns remaining token lifetime in seconds, or 0 if expired.
  static int secondsUntilExpiry(String? token) {
    if (token == null || token.isEmpty) {
      return 0;
    }

    final payload = decodePayload(token);
    if (payload == null) {
      return 0;
    }

    final exp = payload['exp'];
    final expiryEpochSeconds = _asEpochSeconds(exp);
    if (expiryEpochSeconds == null) {
      return 0;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(
      expiryEpochSeconds * 1000,
    );
    final remaining = expiry.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  static int? _asEpochSeconds(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
