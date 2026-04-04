import '../../../../core/api/api_client.dart';
import '../models/iot_device_model.dart';
import '../models/geofence_model.dart';
import '../models/telemetry_model.dart';
import '../models/alert_model.dart';

class FleetOpsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<IoTStats> getIoTStats() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/iot/stats');
      return IoTStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<IoTDevice>> getIoTDevices({int skip = 0, int limit = 20, String? status}) async {
    try {
      final queryParams = {
        'skip': skip,
        'limit': limit,
        if (status != null) 'status': status,
      };
      final response = await _apiClient.get('/api/v1/admin/iot/devices', queryParameters: queryParams);
      return (response.data as List).map((json) => IoTDevice.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendCommand(int deviceId, String commandType, {String? payload}) async {
    try {
      await _apiClient.post('/api/v1/admin/iot/commands', queryParameters: {
        'device_id': deviceId,
        'command_type': commandType,
        if (payload != null) 'payload': payload,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<DeviceCommandLog>> getCommandHistory({int? deviceId, int limit = 50}) async {
    try {
      final queryParams = {
        'limit': limit,
        if (deviceId != null) 'device_id': deviceId,
      };
      final response = await _apiClient.get('/api/v1/admin/iot/commands/history', queryParameters: queryParams);
      return (response.data as List).map((json) => DeviceCommandLog.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Geofence>> getGeofences() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/iot/geofences');
      return (response.data as List).map((json) => Geofence.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> createGeofence(Geofence geofence) async {
    try {
      await _apiClient.post('/api/v1/admin/iot/geofences', data: geofence.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<FleetAlert>> getAlerts({String? severity, bool activeOnly = true}) async {
    try {
      final queryParams = {
        'active_only': activeOnly,
        if (severity != null) 'severity': severity,
      };
      final response = await _apiClient.get('/api/v1/admin/iot/alerts', queryParameters: queryParams);
      return (response.data as List).map((json) => FleetAlert.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> acknowledgeAlert(int alertId) async {
    try {
      await _apiClient.put('/api/v1/admin/iot/alerts/$alertId/acknowledge');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<TelemetryData>> getBatteryTelematics(int batteryId, {int hours = 24}) async {
    try {
      final response = await _apiClient.get('/api/v1/admin/iot/telematics/$batteryId', queryParameters: {'hours': hours});
      return (response.data as List).map((json) => TelemetryData.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
