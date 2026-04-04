import '../../../../core/api/api_client.dart';
import '../models/notification_models.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  NotificationRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/notifications';

  Future<List<PushCampaign>> getCampaigns({String? status}) async {
    final r = await _apiClient.get('$_base/campaigns', queryParameters: {if (status != null) 'status': status});
    return (r.data as List).map((e) => PushCampaign.fromJson(e)).toList();
  }

  Future<PushCampaign> createCampaign(Map<String, dynamic> data) async {
    final r = await _apiClient.post('$_base/campaigns', data: data);
    return PushCampaign.fromJson(r.data);
  }

  Future<void> sendCampaign(int id) async => await _apiClient.post('$_base/campaigns/$id/send');
  Future<void> deleteCampaign(int id) async => await _apiClient.delete('$_base/campaigns/$id');

  Future<List<AutomatedTrigger>> getTriggers() async {
    final r = await _apiClient.get('$_base/triggers');
    return (r.data as List).map((e) => AutomatedTrigger.fromJson(e)).toList();
  }

  Future<void> updateTrigger(int id, Map<String, dynamic> data) async =>
    await _apiClient.patch('$_base/triggers/$id', data: data);
  Future<void> deleteTrigger(int id) async => await _apiClient.delete('$_base/triggers/$id');

  Future<List<NotificationLog>> getLogs({String? channel, String? status, int skip = 0}) async {
    final r = await _apiClient.get('$_base/logs', queryParameters: {
      'skip': skip.toString(), if (channel != null) 'channel': channel, if (status != null) 'status': status});
    return (r.data as List).map((e) => NotificationLog.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getLogStats() async {
    final r = await _apiClient.get('$_base/logs/stats');
    return r.data;
  }

  Future<List<NotificationConfig>> getConfigs() async {
    final r = await _apiClient.get('$_base/config');
    return (r.data as List).map((e) => NotificationConfig.fromJson(e)).toList();
  }

  Future<void> updateConfig(int id, Map<String, dynamic> data) async =>
    await _apiClient.patch('$_base/config/$id', data: data);
  Future<void> testConfig(int id) async => await _apiClient.post('$_base/config/$id/test');
}
