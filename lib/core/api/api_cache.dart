import 'dart:async';

/// Lightweight in-memory cache with per-key TTL and request deduplication.
///
/// **TTL cache** – stores results keyed by a string. If a subsequent request
/// arrives before the TTL expires, the cached value is returned immediately
/// without hitting the network.
///
/// **Request deduplication** – if two callers ask for the same key *while* a
/// network request is still in-flight, the second caller receives the same
/// Future (no duplicate request).
///
/// Usage:
/// ```dart
/// final cache = ApiCache();
/// final data = await cache.getOrFetch(
///   'dashboard_overview',
///   ttl: const Duration(seconds: 60),
///   fetch: () => _api.get('/api/v1/admin/analytics/overview'),
/// );
/// ```
class ApiCache {
  ApiCache();

  // ── Internal storage ──────────────────────────────────────────────────────
  final Map<String, _CacheEntry> _store = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  /// Returns a cached value if fresh, otherwise calls [fetch], caches the
  /// result, and returns it.  Concurrent callers for the same [key] share
  /// a single in-flight Future.
  Future<T> getOrFetch<T>(
    String key, {
    required Duration ttl,
    required Future<T> Function() fetch,
  }) async {
    // 1. Check cache
    final cached = _store[key];
    if (cached != null && !cached.isExpired) {
      return cached.value as T;
    }

    // 2. Deduplicate in-flight requests
    if (_inFlight.containsKey(key)) {
      return (await _inFlight[key]!) as T;
    }

    // 3. Fetch, cache, return
    final completer = Completer<T>();
    _inFlight[key] = completer.future;

    try {
      final result = await fetch();
      _store[key] = _CacheEntry(value: result, expiresAt: DateTime.now().add(ttl));
      completer.complete(result);
      return result;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Invalidate a single key.
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Invalidate all keys that start with [prefix].
  void invalidatePrefix(String prefix) {
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Clear the entire cache.
  void clear() {
    _store.clear();
    _inFlight.clear();
  }

  /// Number of currently cached (possibly stale) entries.
  int get length => _store.length;
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
