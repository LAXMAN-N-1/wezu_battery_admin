import '../../../../core/api/api_client.dart';
import '../models/settings_models.dart';

class SettingsRepository {
  final ApiClient _apiClient;
  SettingsRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/settings';

  Future<Map<String, SystemConfigItem>> getGeneralSettings() async {
    final r = await _apiClient.get('$_base/general');
    final Map<String, SystemConfigItem> result = {};
    (r.data as Map<String, dynamic>).forEach((k, v) {
      result[k] = SystemConfigItem(id: v['id'] ?? 0, key: k, value: v['value']?.toString() ?? '', description: v['description']?.toString());
    });
    return result;
  }
  Future<void> updateGeneralSetting(int id, String value) async => await _apiClient.patch('$_base/general/$id', queryParameters: {'value': value});
  Future<void> createGeneralSetting(String key, String value, {String? desc}) async => await _apiClient.post('$_base/general', queryParameters: {'key': key, 'value': value, if (desc != null) 'description': desc});

  Future<List<FeatureFlagItem>> getFeatureFlags() async {
    final r = await _apiClient.get('$_base/feature-flags');
    return (r.data as List).map((e) => FeatureFlagItem.fromJson(e)).toList();
  }
  Future<void> toggleFeatureFlag(int id, bool isEnabled) async => await _apiClient.patch('$_base/feature-flags/$id', queryParameters: {'is_enabled': isEnabled.toString()});

  Future<List<ApiKeyItem>> getApiKeys() async {
    final r = await _apiClient.get('$_base/api-keys');
    return (r.data as List).map((e) => ApiKeyItem.fromJson(e)).toList();
  }
  Future<void> createApiKey({
    required String serviceName,
    required String keyName,
    required String keyValue,
    required String environment,
    String? apiSecret,
    String? category,
    String? expiresAt,
    List<String>? permissions,
  }) async {
    final params = {
      'service_name': serviceName,
      'key_name': keyName,
      'key_value': keyValue,
      'environment': environment,
      if (apiSecret != null) 'api_secret': apiSecret,
      if (category != null) 'category': category,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (permissions != null) 'permissions': permissions.join(','),
    };
    await _apiClient.post('$_base/api-keys', queryParameters: params);
  }
  Future<void> updateApiKey(int id, {String? val, bool? isActive}) async => await _apiClient.patch('$_base/api-keys/$id', queryParameters: {if (val != null) 'key_value': val, if (isActive != null) 'is_active': isActive.toString()});
  Future<void> deleteApiKey(int id) async => await _apiClient.delete('$_base/api-keys/$id');

  Future<Map<String, dynamic>> getSystemHealth() async {
    final r = await _apiClient.get('$_base/system-health');
    return r.data;
  }

  // Webhooks
  Future<List<WebhookItem>> getWebhooks() async {
    // Note: Mocking if backend doesn't have /webhooks yet
    try {
      final r = await _apiClient.get('$_base/webhooks');
      return (r.data as List).map((e) => WebhookItem.fromJson(e)).toList();
    } catch (e) {
      // Mock data for Screen C UI development
      return [
        WebhookItem(
          id: 1, 
          url: 'https://api.wezu.com/webhooks/payments', 
          events: ['payment.completed', 'payment.failed'], 
          isActive: true,
          lastPingAt: DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
          lastResponseCode: 200,
        ),
        WebhookItem(
          id: 2, 
          url: 'https://hooks.slack.com/services/WEZU/B01/alerts', 
          events: ['battery.low', 'system.error'], 
          isActive: false,
          lastPingAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          lastResponseCode: 404,
        ),
      ];
    }
  }

  Future<void> createWebhook(String url, List<String> events, {String? secret, bool active = true}) async {
    await _apiClient.post('$_base/webhooks', queryParameters: {
      'url': url,
      'events': events.join(','),
      if (secret != null) 'secret': secret,
      'is_active': active.toString(),
    });
  }

  Future<int> testWebhookPing(int id) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    // Return mock success code
    return id == 2 ? 404 : 200;
  }

  Future<void> deleteWebhook(int id) async => await _apiClient.delete('$_base/webhooks/$id');

  Future<String> getPlaintextApiKey(int id) async {
    // Simulate secure network retrieval
    await Future.delayed(const Duration(milliseconds: 800));
    return 'sk_live_51MvR...' + (id * 12345).toString();
  }
}
