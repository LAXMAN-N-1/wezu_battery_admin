import '../../../../core/api/api_client.dart';
import '../models/bess_models.dart';

class BessRepository {
  final ApiClient _apiClient;
  BessRepository([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();
  static const String _base = '/api/v1/admin/bess';

  Future<BessOverviewStats> getOverview() async {
    final response = await _apiClient.get('$_base/overview');
    return BessOverviewStats.fromJson(response.data);
  }

  Future<List<BessUnit>> getUnits({String? status}) async {
    final response = await _apiClient.get('$_base/units',
      queryParameters: {if (status != null) 'status': status});
    return (response.data as List).map((e) => BessUnit.fromJson(e)).toList();
  }

  Future<List<BessEnergyLog>> getEnergyLogs({int? bessUnitId, int hours = 24}) async {
    final response = await _apiClient.get('$_base/energy-logs',
      queryParameters: {'hours': hours.toString(), if (bessUnitId != null) 'bess_unit_id': bessUnitId.toString()});
    return (response.data as List).map((e) => BessEnergyLog.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getEnergySummary({int days = 7}) async {
    final response = await _apiClient.get('$_base/energy-logs/summary',
      queryParameters: {'days': days.toString()});
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<BessGridEvent>> getGridEvents({int? bessUnitId, String? eventType, int days = 30}) async {
    final response = await _apiClient.get('$_base/grid-events',
      queryParameters: {'days': days.toString(),
        if (bessUnitId != null) 'bess_unit_id': bessUnitId.toString(),
        if (eventType != null) 'event_type': eventType});
    return (response.data as List).map((e) => BessGridEvent.fromJson(e)).toList();
  }

  Future<List<BessReport>> getReports({String? reportType, int? bessUnitId}) async {
    final response = await _apiClient.get('$_base/reports',
      queryParameters: {if (reportType != null) 'report_type': reportType,
        if (bessUnitId != null) 'bess_unit_id': bessUnitId.toString()});
    return (response.data as List).map((e) => BessReport.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getReportsKpi() async {
    final response = await _apiClient.get('$_base/reports/kpi');
    return response.data;
  }
}
