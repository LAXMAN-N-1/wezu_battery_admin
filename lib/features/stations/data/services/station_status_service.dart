import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_status.dart';
import '../models/station.dart';

class StationStatusService {
  static const _historyKey = 'station_status_history_v1';
  static const _maxHistory = 50;
  static const _baseUrl = 'http://127.0.0.1:8000/api/v1';

  final _rng = Random();
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  StationStatusService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'admin_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  // -------------------------------------------------------
  // SINGLE SOURCE OF TRUTH: local station.status from stationsProvider.
  //
  // We deliberately do NOT fetch from /admin/iot/stations/status because
  // mock station IDs (SharedPreferences) and real DB IDs are not in sync —
  // any override would corrupt the status shown in the Stations list.
  //
  // The stream refreshes every 10 s so the timestamp stays live and
  // any edits made in the Station form are reflected automatically.
  // -------------------------------------------------------
  Stream<List<StationStatusEvent>> statusStream(
    List<Station> stations, {
    Map<int, MaintenanceSchedule> maintenanceSchedules = const {},
  }) async* {
    // Emit immediately using local station data
    yield _buildFromLocalStations(
      stations,
      maintenanceSchedules: maintenanceSchedules,
    );

    // Refresh every 10 seconds (reacts to station list edits)
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      final events = _buildFromLocalStations(
        stations,
        maintenanceSchedules: maintenanceSchedules,
      );
      await saveHistory(events);
      yield events;
    }
  }

  // -------------------------------------------------------
  // Build status events directly from local station.status field.
  // If a station has an active MaintenanceSchedule, that takes priority.
  // This is the ONLY data source — same as the Stations list.
  // -------------------------------------------------------
  List<StationStatusEvent> _buildFromLocalStations(
    List<Station> stations, {
    Map<int, MaintenanceSchedule> maintenanceSchedules = const {},
  }) {
    return stations.map((s) {
      var status = _statusFromString(s.status);

      // Active maintenance schedule overrides the station's stored status
      final ms = maintenanceSchedules[s.id];
      if (ms != null && ms.isActive) {
        status = StationOperationalStatus.maintenance;
      }

      final errorMsg = status == StationOperationalStatus.error
          ? _errorMessages[_rng.nextInt(_errorMessages.length)]
          : null;

      return StationStatusEvent(
        stationId: s.id,
        stationName: s.name,
        stationAddress: s.address,
        status: status,
        timestamp: DateTime.now(),
        errorMessage: errorMsg,
        troubleshootingSteps: getTroubleshooting(errorMsg),
      );
    }).toList();
  }

  // -------------------------------------------------------
  // Fetch recent error logs from backend monitoring endpoint
  // -------------------------------------------------------
  Future<List<BackendErrorLog>> fetchErrorLogs({int limit = 30}) async {
    try {
      final response = await _dio.get(
        '/admin/monitoring/errors',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> errors = data is Map
            ? ((data['errors'] as List?) ?? [])
            : [];
        return errors
            .map((e) => BackendErrorLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // -------------------------------------------------------
  // Status string → enum mapping (consistent with Stations list)
  // -------------------------------------------------------
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
        // Unknown status → treat as offline rather than assuming operational
        return StationOperationalStatus.offline;
    }
  }

  // -------------------------------------------------------
  // Error messages & troubleshooting (for error-state stations)
  // -------------------------------------------------------
  static const _errorMessages = [
    'Battery slot connection failure on port 3',
    'Overcurrent detected on charger module B',
    'Temperature sensor reading out of bounds',
    'Communication timeout with central controller',
    'Power supply voltage out of spec (Δ12%)',
  ];

  static const _troubleshooting = {
    'Battery slot connection failure on port 3': [
      'Inspect port 3 for debris or corrosion',
      'Re-seat the battery connector',
      'Run diagnostic: admin → station → run_hw_test',
      'Contact field team if issue persists',
    ],
    'Overcurrent detected on charger module B': [
      'Power-cycle the charger module (30 s)',
      'Check input cable integrity',
      'Verify load balancing across charger banks',
      'Escalate to electrical team if recurrence > 3×',
    ],
    'Temperature sensor reading out of bounds': [
      'Check ambient temperature at station',
      'Clean cooling vents and verify airflow',
      'Verify sensor wiring harness',
      'Replace sensor if issue persists after reboot',
    ],
    'Communication timeout with central controller': [
      'Check network/SIM signal strength at site',
      'Restart the IoT gateway module',
      'Verify firewall rules for port 8883 (MQTT)',
      'Contact NOC if timeout > 15 min',
    ],
    'Power supply voltage out of spec (Δ12%)': [
      'Verify incoming mains voltage at distribution panel',
      'Check UPS health and battery state',
      'Inspect voltage regulator output',
      'Contact utility if mains deviation persists',
    ],
  };

  List<String> getTroubleshooting(String? errorMessage) {
    if (errorMessage == null) return [];
    return _troubleshooting[errorMessage] ?? ['Contact field support team'];
  }

  // ---- History Persistence ----

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

// -------------------------------------------------------
// Model for backend error log entry (/admin/monitoring/errors)
// -------------------------------------------------------
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

  factory BackendErrorLog.fromJson(Map<String, dynamic> json) =>
      BackendErrorLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        eventType: json['event_type'] as String? ?? 'unknown',
        severity: json['severity'] as String? ?? 'info',
        details: json['details'] as Map<String, dynamic>?,
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
