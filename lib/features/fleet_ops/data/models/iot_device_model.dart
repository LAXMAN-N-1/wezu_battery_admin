class IoTDevice {
  final int id;
  final String deviceId;
  final String deviceType;
  final String status;
  final String communicationProtocol;
  final String? firmwareVersion;
  final DateTime? lastHeartbeat;
  final String? lastIpAddress;

  IoTDevice({
    required this.id,
    required this.deviceId,
    required this.deviceType,
    required this.status,
    required this.communicationProtocol,
    this.firmwareVersion,
    this.lastHeartbeat,
    this.lastIpAddress,
  });

  factory IoTDevice.fromJson(Map<String, dynamic> json) {
    return IoTDevice(
      id: json['id'],
      deviceId: json['device_id'],
      deviceType: json['device_type'] ?? 'tracker_v1',
      status: json['status'] ?? 'offline',
      communicationProtocol: json['communication_protocol'] ?? 'mqtt',
      firmwareVersion: json['firmware_version'],
      lastHeartbeat: json['last_heartbeat'] != null ? DateTime.parse(json['last_heartbeat']) : null,
      lastIpAddress: json['last_ip_address'],
    );
  }
}

class IoTStats {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final int activeAlerts;
  final double healthScore;

  IoTStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.activeAlerts,
    required this.healthScore,
  });

  factory IoTStats.fromJson(Map<String, dynamic> json) {
    return IoTStats(
      totalDevices: json['total_devices'],
      onlineDevices: json['online_devices'],
      offlineDevices: json['offline_devices'],
      activeAlerts: json['active_alerts'],
      healthScore: (json['health_score'] as num).toDouble(),
    );
  }
}

class DeviceCommandLog {
  final int id;
  final int deviceId;
  final String commandType;
  final String? payload;
  final String status;
  final DateTime createdAt;
  final DateTime? executedAt;

  DeviceCommandLog({
    required this.id,
    required this.deviceId,
    required this.commandType,
    this.payload,
    required this.status,
    required this.createdAt,
    this.executedAt,
  });

  factory DeviceCommandLog.fromJson(Map<String, dynamic> json) {
    return DeviceCommandLog(
      id: json['id'],
      deviceId: json['device_id'],
      commandType: json['command_type'],
      payload: json['payload'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      executedAt: json['executed_at'] != null ? DateTime.parse(json['executed_at']) : null,
    );
  }
}
