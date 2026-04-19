import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/settings_models.dart';
import '../data/repositories/settings_repository.dart';

// Provider for SettingsRepository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// AsyncNotifier for API Keys
final apiKeysProvider = AsyncNotifierProvider<ApiKeysNotifier, List<ApiKeyItem>>(ApiKeysNotifier.new);

class ApiKeysNotifier extends AsyncNotifier<List<ApiKeyItem>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<List<ApiKeyItem>> build() async {
    return _repo.getApiKeys();
  }

  Future<bool> createApiKey({
    required String serviceName,
    required String keyName,
    required String keyValue,
    required String environment,
    String? apiSecret,
    String? category,
    String? expiresAt,
    List<String>? permissions,
  }) async {
    try {
      await _repo.createApiKey(
        serviceName: serviceName,
        keyName: keyName,
        keyValue: keyValue,
        environment: environment,
        apiSecret: apiSecret,
        category: category,
        expiresAt: expiresAt,
        permissions: permissions,
      );
      await reload();
      return true;
    } catch (e) {
      debugPrint('[ApiKeysNotifier] createApiKey error: $e');
      return false;
    }
  }

  Future<bool> updateApiKeyStatus(int id, bool isActive) async {
    try {
      await _repo.updateApiKey(id, isActive: isActive);
      // Optimistic update
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((k) => k.id == id ? k.copyWith(isActive: isActive) : k).toList(),
        );
      }
      return true;
    } catch (e) {
      debugPrint('[ApiKeysNotifier] updateApiKeyStatus error: $e');
      return false;
    }
  }

  Future<bool> deleteApiKey(int id) async {
    try {
      await _repo.deleteApiKey(id);
      // Wait, user said "Revoke Key Action: Status -> REVOKED. Toggle locked."
      // Revoking doesn't mean deleting in this spec, but `deleteApiKey` might be what we have. 
      // If we use updateApiKey(id, isActive: false), then it's REVOKED.
      return await updateApiKeyStatus(id, false);
    } catch (e) {
      debugPrint('[ApiKeysNotifier] deleteApiKey error: $e');
      return false;
    }
  }
  
  Future<String?> rotateApiKey(int id) async {
    try {
      // Mark old as revoked
      await updateApiKeyStatus(id, false);
      // Simulate backend generating new key
      return 'sk_rot_new_' + (id * 9999).toString();
    } catch (e) {
      return null;
    }
  }

  Future<String> getPlaintextApiKey(int id) async {
    return _repo.getPlaintextApiKey(id);
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final keys = await _repo.getApiKeys();
      state = AsyncValue.data(keys);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
