// lib/features/battery_health/data/repositories/health_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/health_models.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HealthRepository(apiClient);
});

class HealthRepository {
  final ApiClient _api;
  final String _baseUrl = '/api/v1/admin/health';

  HealthRepository(this._api);

  Future<HealthOverview> getOverview() async {
    final response = await _api.get('$_baseUrl/overview');
    return HealthOverview.fromJson(response.data);
  }

  Future<List<HealthBattery>> getBatteries({
    String? healthRange,
    String sortBy = 'health_desc',
    bool? needsAttention,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{
      'sort_by': sortBy,
      'page': page,
      'limit': limit,
    };
    if (healthRange != null) params['health_range'] = healthRange;
    if (needsAttention != null) params['needs_attention'] = needsAttention;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _api.get('$_baseUrl/batteries', queryParameters: params);
    return (response.data as List).map((json) => HealthBattery.fromJson(json)).toList();
  }

  Future<HealthBatteryDetail> getBatteryDetail(String batteryId) async {
    final response = await _api.get('$_baseUrl/batteries/$batteryId');
    return HealthBatteryDetail.fromJson(response.data);
  }

  Future<List<HealthSnapshot>> getBatterySnapshots(String batteryId, {int days = 90}) async {
    final response = await _api.get('$_baseUrl/batteries/$batteryId/snapshots', queryParameters: {'days': days});
    return (response.data as List).map((json) => HealthSnapshot.fromJson(json)).toList();
  }

  Future<HealthSnapshot> recordSnapshot(String batteryId, Map<String, dynamic> data) async {
    final response = await _api.post('$_baseUrl/batteries/$batteryId/snapshot', data: data);
    return HealthSnapshot.fromJson(response.data);
  }

  Future<List<HealthAlert>> getAlerts({String? severity, String? batteryId, bool includeResolved = false}) async {
    final params = <String, dynamic>{'include_resolved': includeResolved};
    if (severity != null) params['severity'] = severity;
    if (batteryId != null) params['battery_id'] = batteryId;

    final response = await _api.get('$_baseUrl/alerts', queryParameters: params);
    return (response.data as List).map((json) => HealthAlert.fromJson(json)).toList();
  }

  Future<void> resolveAlert(int alertId, String reason) async {
    await _api.post('$_baseUrl/alerts/$alertId/resolve', data: {'reason': reason});
  }

  Future<MaintenanceSchedule> scheduleMaintenance(Map<String, dynamic> data) async {
    final response = await _api.post('$_baseUrl/maintenance', data: data);
    return MaintenanceSchedule.fromJson(response.data);
  }

  Future<List<MaintenanceSchedule>> getMaintenanceList({String? status, int? upcomingDays}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (upcomingDays != null) params['upcoming_days'] = upcomingDays;

    final response = await _api.get('$_baseUrl/maintenance', queryParameters: params);
    return (response.data as List).map((json) => MaintenanceSchedule.fromJson(json)).toList();
  }

  Future<HealthAnalytics> getAnalytics() async {
    final response = await _api.get('$_baseUrl/analytics');
    return HealthAnalytics.fromJson(response.data);
  }
}
