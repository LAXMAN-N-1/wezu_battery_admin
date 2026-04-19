import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/settings_models.dart';
import '../data/repositories/settings_repository.dart';
import 'api_keys_provider.dart';

final webhooksProvider = AsyncNotifierProvider<WebhooksNotifier, List<WebhookItem>>(WebhooksNotifier.new);

class WebhooksNotifier extends AsyncNotifier<List<WebhookItem>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<List<WebhookItem>> build() async {
    return _repo.getWebhooks();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final webhooks = await _repo.getWebhooks();
      state = AsyncValue.data(webhooks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createWebhook(String url, List<String> events, {String? secret, bool active = true}) async {
    try {
      await _repo.createWebhook(url, events, secret: secret, active: active);
      await reload();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> testPing(int id) async {
    if (!state.hasValue) return;

    // Start loading state for specific item
    _updateItemLocal(id, lastResponseCode: -1); // -1 = Loading

    try {
      final code = await _repo.testWebhookPing(id);
      _updateItemLocal(id, lastResponseCode: code, lastPingAt: DateTime.now().toIso8601String());
      
      // Reset code after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _updateItemLocal(id, lastResponseCode: null);
      });
    } catch (e) {
      _updateItemLocal(id, lastResponseCode: 500);
    }
  }

  Future<bool> deleteWebhook(int id) async {
    try {
      await _repo.deleteWebhook(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((w) => w.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void _updateItemLocal(int id, {int? lastResponseCode, String? lastPingAt, bool? isActive}) {
    if (!state.hasValue) return;
    state = AsyncValue.data(
      state.value!.map((w) {
        if (w.id == id) {
          return w.copyWith(
            lastResponseCode: lastResponseCode,
            lastPingAt: lastPingAt ?? w.lastPingAt,
            isActive: isActive ?? w.isActive,
          );
        }
        return w;
      }).toList(),
    );
  }
}
