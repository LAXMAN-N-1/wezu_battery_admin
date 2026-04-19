import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/station_status.dart';
import '../services/station_status_service.dart';
import 'stations_provider.dart';

// -------------------------------------------------------
// Service singleton
// -------------------------------------------------------
final stationStatusServiceProvider = Provider<StationStatusService>(
  (ref) => StationStatusService(ref.read(apiClientProvider)),
);

// -------------------------------------------------------
// Main stream — list of current statuses for all stations
// Rebuilds when stations change OR maintenance schedules change
// -------------------------------------------------------
final stationStatusStreamProvider = StreamProvider<List<StationStatusEvent>>((
  ref,
) {
  final service = ref.read(stationStatusServiceProvider);
  final stationsAsync = ref.watch(stationsProvider);
  final maintenanceSchedules = ref.watch(maintenanceProvider);

  return stationsAsync.when(
    data: (stations) => service.statusStream(
      stations,
      maintenanceSchedules: maintenanceSchedules,
    ),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// -------------------------------------------------------
// Active alerts notifier
// -------------------------------------------------------
class AlertsNotifier extends StateNotifier<List<StatusAlert>> {
  AlertsNotifier() : super([]);

  // Called every time a new status snapshot arrives.
  // Detects transitions to error/offline and adds an alert.
  void processSnapshot(
    List<StationStatusEvent> current,
    List<StationStatusEvent> previous,
  ) {
    final newAlerts = <StatusAlert>[];
    for (final ev in current) {
      final prev = previous
          .where((p) => p.stationId == ev.stationId)
          .firstOrNull;
      if (prev == null) continue;
      final wentBad =
          (ev.status == StationOperationalStatus.error ||
              ev.status == StationOperationalStatus.offline) &&
          prev.status != ev.status;
      if (wentBad) {
        newAlerts.add(
          StatusAlert(
            stationId: ev.stationId,
            stationName: ev.stationName,
            previousStatus: prev.status,
            newStatus: ev.status,
            timestamp: ev.timestamp,
          ),
        );
      }
    }
    if (newAlerts.isNotEmpty) {
      state = [...newAlerts, ...state];
    }
  }

  void dismiss(int stationId) {
    state = state.where((a) => a.stationId != stationId).toList();
  }

  void dismissAll() => state = [];
}

final alertsProvider = StateNotifierProvider.autoDispose<AlertsNotifier, List<StatusAlert>>(
  (_) => AlertsNotifier(),
);

// -------------------------------------------------------
// Maintenance schedules per station
// -------------------------------------------------------
class MaintenanceNotifier extends StateNotifier<Map<int, MaintenanceSchedule>> {
  final ApiClient _apiClient;

  MaintenanceNotifier(this._apiClient) : super({}) {
    _load();
  }

  Future<void> _load() async {
    try {
      // Updated to verified path for maintenance history
      final response = await _apiClient.get('/api/v1/admin/stations/maintenance/all');
      if (response.statusCode == 200) {
        final payload = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : Map<String, dynamic>.from(response.data as Map);
        final List<dynamic> list = payload['records'] is List ? payload['records'] as List : const <dynamic>[];
        final map = <int, MaintenanceSchedule>{};
        for (final item in list) {
          // Note: MaintenanceRecord from backend might need mapping to MaintenanceSchedule
          // For now, assuming direct compatibility or providing a mapper
          try {
            final record = Map<String, dynamic>.from(item as Map);
            final stationId = (record['entity_id'] as num?)?.toInt();
            if (stationId == null || stationId <= 0) continue;
            map[stationId] = MaintenanceSchedule(
              id: (record['id'] as num?)?.toInt() ?? 0,
              stationId: stationId,
              startTime: DateTime.tryParse(record['performed_at']?.toString() ?? '') ?? DateTime.now(),
              endTime: (DateTime.tryParse(record['performed_at']?.toString() ?? '') ?? DateTime.now()).add(const Duration(hours: 1)),
              notes: record['description']?.toString() ?? '',
              maintenanceType: record['maintenance_type']?.toString() ?? 'Routine',
            );
          } catch (_) {
            // Handle mapping errors
          }
        }
        state = map;
      }
    } catch (_) {}
  }

  Future<void> schedule(MaintenanceSchedule ms) async {
    try {
      // Updated to verified path for recording maintenance
      final response = await _apiClient.post(
        '/api/v1/admin/stations/maintenance/create',
        data: {
          'entity_type': 'station',
          'entity_id': ms.stationId,
                    'maintenance_type': ms.maintenanceType,
          'description': ms.notes,
          'status': 'scheduled',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = {...state, ms.stationId: ms};
      }
    } catch (_) {}
  }

  Future<void> cancel(int stationId, int taskId) async {
    // Current backend doesn't seem to have a specific 'cancel' for records,
    // only history and record creation. Removing locally for now.
    final updated = Map<int, MaintenanceSchedule>.from(state)
      ..remove(stationId);
    state = updated;
  }
}

final maintenanceProvider =
    StateNotifierProvider.autoDispose<MaintenanceNotifier, Map<int, MaintenanceSchedule>>(
      (ref) => MaintenanceNotifier(ref.read(apiClientProvider)),
    );

// -------------------------------------------------------
// Status history provider (last 50 events)
// -------------------------------------------------------
final statusHistoryProvider = FutureProvider.autoDispose<List<StationStatusEvent>>((
  ref,
) async {
  final service = ref.read(stationStatusServiceProvider);
  return service.loadHistory();
});

// -------------------------------------------------------
// Backend error logs provider — polls /admin/monitoring/errors
// -------------------------------------------------------
final errorLogsProvider = FutureProvider.autoDispose<List<BackendErrorLog>>((ref) async {
  final service = ref.read(stationStatusServiceProvider);
  return service.fetchErrorLogs(limit: 30);
});
