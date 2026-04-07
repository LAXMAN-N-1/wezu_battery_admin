import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_cache.dart';
import '../models/settings_models.dart';

class SettingsRepository {
  final ApiClient _apiClient;
  final ApiCache _cache = ApiCache();
  SettingsRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/settings';

  Future<Map<String, SystemConfigItem>> getGeneralSettings() async {
    return _cache.getOrFetch<Map<String, SystemConfigItem>>(
      'general_settings',
      ttl: const Duration(seconds: 120),
      fetch: () async {
        final r = await _apiClient.get('$_base/general');
        final Map<String, SystemConfigItem> result = {};
        (r.data as Map<String, dynamic>).forEach((k, v) {
          result[k] = SystemConfigItem(id: v['id'] ?? 0, key: k, value: v['value']?.toString() ?? '', description: v['description']?.toString());
        });
        return result;
      },
    );
  }
  Future<void> updateGeneralSetting(int id, String value) async {
    await _apiClient.patch('$_base/general/$id', queryParameters: {'value': value});
    _cache.invalidate('general_settings');
  }
  Future<void> createGeneralSetting(String key, String value, {String? desc}) async {
    await _apiClient.post('$_base/general', queryParameters: {'key': key, 'value': value, if (desc != null) 'description': desc});
    _cache.invalidate('general_settings');
  }

  Future<List<FeatureFlagItem>> getFeatureFlags() async {
    final r = await _apiClient.get('$_base/feature-flags');
    return (r.data as List).map((e) => FeatureFlagItem.fromJson(e)).toList();
  }
  Future<void> toggleFeatureFlag(int id, bool isEnabled) async => await _apiClient.patch('$_base/feature-flags/$id', queryParameters: {'is_enabled': isEnabled.toString()});

  Future<List<ApiKeyItem>> getApiKeys() async {
    final r = await _apiClient.get('$_base/api-keys');
    return (r.data as List).map((e) => ApiKeyItem.fromJson(e)).toList();
  }
  Future<void> createApiKey(String svc, String name, String val, String env) async => await _apiClient.post('$_base/api-keys', queryParameters: {'service_name': svc, 'key_name': name, 'key_value': val, 'environment': env});
  Future<void> updateApiKey(int id, {String? val, bool? isActive}) async => await _apiClient.patch('$_base/api-keys/$id', queryParameters: {if (val != null) 'key_value': val, if (isActive != null) 'is_active': isActive.toString()});
  Future<void> deleteApiKey(int id) async => await _apiClient.delete('$_base/api-keys/$id');

  Future<Map<String, dynamic>> getSystemHealth() async {
    final r = await _apiClient.get('$_base/system-health');
    return r.data;
  }
}
