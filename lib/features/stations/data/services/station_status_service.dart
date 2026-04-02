import 'package:flutter/material.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_status.dart';
import '../models/station.dart';
import '../../../../core/api/api_client.dart';

class StationStatusService {
  static const _historyKey = 'station_status_history_v1';
  static const _maxHistory = 50;

  final ApiClient _apiClient;

  StationStatusService(this._apiClient);

  Stream<List<StationStatusEvent>> statusStream(
    List<Station> stations, {
    Map<int, MaintenanceSchedule> maintenanceSchedules = const {},
  }) async* {
    while (true) {
      final events = _buildFromStations(
        stations,
        maintenanceSchedules: maintenanceSchedules,
      );
      await saveHistory(events);
      yield events;
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  List<StationStatusEvent> _buildFromStations(
    List<Station> stations, {
    Map<int, MaintenanceSchedule> maintenanceSchedules = const {},
  }) {
    return stations.map((s) {
      var status = _statusFromString(s.status);
      final schedule = maintenanceSchedules[s.id];
      if (schedule != null && schedule.isActive) {
        status = StationOperationalStatus.maintenance;
      }

      return StationStatusEvent(
        stationId: s.id,
        stationName: s.name,
        stationAddress: s.address,
        status: status,
        timestamp: DateTime.now(),
      );
    }).toList();
  }

  Future<List<BackendErrorLog>> fetchErrorLogs({int limit = 30}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/security/security-events',
      queryParameters: {'limit': limit},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List ? payload['items'] as List : const <dynamic>[];

    return items
        .whereType<Map>()
        .map((raw) => BackendErrorLog.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  StationOperationalStatus _statusFromString(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'operational':
        return StationOperationalStatus.operational;
      case 'maintenance':
        return StationOperationalStatus.maintenance;
      case 'inactive':
      case 'offline':
        return StationOperationalStatus.offline;
      case 'error':
        return StationOperationalStatus.error;
      default:
        return StationOperationalStatus.offline;
    }
  }

  List<String> getTroubleshooting(String? errorMessage) {
    if (errorMessage == null || errorMessage.trim().isEmpty) return [];
    return [
      'Review the corresponding backend security event for details.',
      'Check the station telemetry and latest maintenance records before retrying.',
    ];
  }

  Future<void> saveHistory(List<StationStatusEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadHistory();
    final combined = [...events, ...existing];
    final trimmed = combined.take(_maxHistory).toList();
    await prefs.setString(
      _historyKey,
      '[${trimmed.map((e) => e.toJsonString()).join(',')}]',
    );
  }

  Future<List<StationStatusEvent>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      return StationStatusEvent.listFromJsonString(raw);
    } catch (_) {
      return [];
    }
  }
}

class BackendErrorLog {
  final int id;
  final String eventType;
  final String severity;
  final Map<String, dynamic>? details;
  final String? sourceIp;
  final DateTime timestamp;
  final bool isResolved;

  const BackendErrorLog({
    required this.id,
    required this.eventType,
    required this.severity,
    this.details,
    this.sourceIp,
    required this.timestamp,
    required this.isResolved,
  });

  factory BackendErrorLog.fromJson(Map<String, dynamic> json) => BackendErrorLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        eventType: json['event_type'] as String? ?? 'unknown',
        severity: json['severity'] as String? ?? 'info',
        details: json['details'] is Map ? Map<String, dynamic>.from(json['details'] as Map) : null,
        sourceIp: json['source_ip'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isResolved: json['is_resolved'] as bool? ?? false,
      );

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
